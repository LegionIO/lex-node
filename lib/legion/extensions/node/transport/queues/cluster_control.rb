# frozen_string_literal: true

require 'legion/extensions/node/config'

module Legion
  module Extensions
    module Node
      module Transport
        module Queues
          class ClusterControl < Legion::Transport::Queue
            def queue_name
              "legion.cluster.control.#{Legion::Settings[:client][:name]}"
            end

            def queue_options
              options = Legion::Extensions::Node::Config.control_queue
              { durable:     truthy?(options[:durable], default: true),
                exclusive:   truthy?(options[:exclusive], default: false),
                auto_delete: truthy?(options[:auto_delete], default: false),
                arguments:   queue_arguments(options) }
            end

            private

            def queue_arguments(options)
              {
                'x-queue-type':  options[:queue_type],
                'x-expires':     positive_integer(options[:expires_ms]),
                'x-message-ttl': positive_integer(options[:message_ttl_ms]),
                'x-max-length':  positive_integer(options[:max_length])
              }.compact
            end

            def positive_integer(value)
              return value if value.is_a?(Integer) && value.positive?
              return nil unless value.to_s.match?(/\A\d+\z/)

              parsed = value.to_i
              parsed.positive? ? parsed : nil
            end

            def truthy?(value, default:)
              return default if value.nil?

              value == true || value.to_s == 'true'
            end
          end
        end
      end
    end
  end
end
