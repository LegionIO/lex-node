# frozen_string_literal: true

require 'legion/extensions/node/control_auth'

module Legion
  module Extensions
    module Node
      module Transport
        module Messages
          class ClusterKillswitch < Legion::Transport::Message
            ROUTING_KEY = 'settings.extensions.blocked'

            def routing_key
              ROUTING_KEY
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
              Legion::Extensions::Node::ControlAuth.sign(
                function: 'update_settings',
                settings: { extensions: { blocked: [@options[:extension]] } },
                restart:  true
              )
            end

            def validate
              raise 'extension must be a String' unless @options[:extension].is_a?(String)

              @valid = true
            end
          end
        end
      end
    end
  end
end
