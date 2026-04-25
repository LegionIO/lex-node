# frozen_string_literal: true

require 'legion/extensions/node/control_auth'

module Legion
  module Extensions
    module Node
      module Actor
        class ClusterControl < Legion::Extensions::Actors::Subscription
          def runner_class
            Legion::Extensions::Node::Runners::Node
          end

          def queue_class
            Legion::Extensions::Node::Transport::Queues::ClusterControl
          end

          def disabled?
            false
          end

          def use_runner?
            true
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end

          def process_message(message, metadata, delivery_info)
            Legion::Extensions::Node::ControlAuth.verify!(super)
          end
        end
      end
    end
  end
end
