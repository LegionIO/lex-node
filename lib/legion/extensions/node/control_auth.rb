# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require 'json'

module Legion
  module Extensions
    module Node
      module ControlAuth
        MAX_SKEW_SECONDS = 300

        class UnauthorizedControlMessage < StandardError; end

        module_function

        def sign(payload)
          normalized = deep_symbolize(payload).dup
          control = {
            sender:    node_name,
            timestamp: Time.now.utc.to_i,
            nonce:     SecureRandom.hex(16)
          }
          normalized[:control] = control.merge(signature: signature_for(normalized.merge(control: control)))
          normalized
        end

        def verify!(payload)
          normalized = deep_symbolize(payload)
          raise UnauthorizedControlMessage, 'missing control signature' unless normalized.is_a?(Hash)

          control = normalized[:control]
          raise UnauthorizedControlMessage, 'missing control signature' unless control.is_a?(Hash)

          signature = control[:signature].to_s
          raise UnauthorizedControlMessage, 'missing control signature' if signature.empty?
          raise UnauthorizedControlMessage, 'stale control message' unless fresh_timestamp?(control[:timestamp])
          raise UnauthorizedControlMessage, 'invalid control nonce' unless valid_nonce?(control[:nonce])

          unsigned_control = control.dup
          unsigned_control.delete(:signature)
          expected = signature_for(normalized.merge(control: unsigned_control))
          raise UnauthorizedControlMessage, 'invalid control signature' unless secure_compare(signature, expected)

          normalized
        end

        def secret
          configured_secret || ENV.fetch('LEGION_NODE_CONTROL_SECRET', nil)
        end

        def configured_secret
          if defined?(Legion::Settings) && Legion::Settings.respond_to?(:dig)
            Legion::Settings.dig(:cluster, :control_secret) ||
              Legion::Settings.dig(:crypt, :cluster_secret)
          end
        rescue StandardError => e
          log.debug("control secret lookup failed: #{e.message}")
          nil
        end

        def signature_for(payload)
          value = secret
          raise UnauthorizedControlMessage, 'cluster control secret is not configured' if value.to_s.empty?

          OpenSSL::HMAC.hexdigest('SHA256', value.to_s, canonical_json(payload))
        end

        def canonical_json(value)
          ::JSON.generate(canonicalize(value))
        end

        def canonicalize(value)
          case value
          when Hash
            value.each_with_object({}) do |(key, val), result|
              result[key.to_s] = canonicalize(val)
            end.sort.to_h
          when Array
            value.map { |item| canonicalize(item) }
          else
            value
          end
        end

        def deep_symbolize(value)
          case value
          when Hash
            value.each_with_object({}) do |(key, val), result|
              result[key.to_sym] = deep_symbolize(val)
            end
          when Array
            value.map { |item| deep_symbolize(item) }
          else
            value
          end
        end

        def fresh_timestamp?(timestamp)
          ts = Integer(timestamp)
          (Time.now.utc.to_i - ts).abs <= MAX_SKEW_SECONDS
        rescue ArgumentError, TypeError => e
          log.debug("control timestamp validation failed: #{e.message}")
          false
        end

        def valid_nonce?(nonce)
          nonce.to_s.match?(/\A[0-9a-f]{32}\z/i)
        end

        def secure_compare(left, right)
          return false unless left.bytesize == right.bytesize

          left.bytes.zip(right.bytes).reduce(0) { |acc, (a, b)| acc | (a ^ b) }.zero?
        end

        def node_name
          (Legion::Settings[:client]&.fetch(:name, nil) if defined?(Legion::Settings)) || 'unknown'
        rescue StandardError => e
          log.debug("node name lookup failed: #{e.message}")
          'unknown'
        end

        def log
          Legion::Logging.respond_to?(:logger) ? Legion::Logging.logger : Legion::Logging
        end
      end
    end
  end
end
