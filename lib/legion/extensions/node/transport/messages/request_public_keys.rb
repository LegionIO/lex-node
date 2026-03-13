# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Transport
        module Messages
          class RequestPublicKeys < Legion::Transport::Message
            def routing_key
              'node'
            end

            def type
              'task'
            end

            def encrypt?
              false
            end

            def validate
              @valid = true
            end
          end
        end
      end
    end
  end
end
