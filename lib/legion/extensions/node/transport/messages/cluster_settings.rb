# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Transport
        module Messages
          class ClusterSettings < Legion::Transport::Message
            def routing_key
              @options.fetch(:routing_key, 'settings')
            end

            def exchange
              Legion::Extensions::Node::Transport::Exchanges::ClusterControl
            end

            def type
              'task'
            end

            def encrypt?
              false
            end

            def message
              {
                function: 'update_settings',
                settings: @options[:settings],
                restart:  @options.fetch(:restart, false)
              }
            end

            def validate
              raise 'settings must be a Hash' unless @options[:settings].is_a?(Hash)

              @valid = true
            end
          end
        end
      end
    end
  end
end
