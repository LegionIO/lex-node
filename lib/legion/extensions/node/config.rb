# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Config
        DEFAULT_SETTINGS = {
          cluster_control: {
            auth:  {
              mode:                   'auto',
              timestamp_skew_seconds: 300,
              nonce_bytes:            16
            },
            queue: {
              durable:        true,
              exclusive:      false,
              auto_delete:    false,
              queue_type:     'classic',
              expires_ms:     604_800_000,
              message_ttl_ms: 86_400_000,
              max_length:     1000
            }
          }
        }.freeze

        module_function

        def default_settings
          deep_dup(DEFAULT_SETTINGS)
        end

        def cluster_control
          deep_merge(default_settings[:cluster_control], extension_settings[:cluster_control] || {})
        end

        def control_auth
          cluster_control[:auth] || {}
        end

        def control_queue
          cluster_control[:queue] || {}
        end

        def extension_settings
          return {} unless defined?(Legion::Settings) && Legion::Settings.respond_to?(:dig)

          settings = Legion::Settings.dig(:extensions, :node)
          settings.is_a?(Hash) ? symbolize_keys(settings) : {}
        rescue StandardError => e
          log.debug("node settings lookup failed: #{e.message}")
          {}
        end

        def deep_merge(base, override)
          base_hash = symbolize_keys(base)
          override_hash = symbolize_keys(override)
          base_hash.merge(override_hash) do |_key, old_value, new_value|
            old_value.is_a?(Hash) && new_value.is_a?(Hash) ? deep_merge(old_value, new_value) : new_value
          end
        end

        def deep_dup(value)
          case value
          when Hash
            value.each_with_object({}) { |(key, val), result| result[key] = deep_dup(val) }
          when Array
            value.map { |item| deep_dup(item) }
          else
            value
          end
        end

        def symbolize_keys(value)
          case value
          when Hash
            value.each_with_object({}) { |(key, val), result| result[key.to_sym] = symbolize_keys(val) }
          when Array
            value.map { |item| symbolize_keys(item) }
          else
            value
          end
        end

        def log
          Legion::Logging.respond_to?(:logger) ? Legion::Logging.logger : Legion::Logging
        end
      end
    end
  end
end
