# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Actor
        class PushKey < Legion::Extensions::Actors::Once
          def function
            'request_public_keys'
          end

          def runner_class
            Legion::Extensions::Node::Runners::Crypt
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
        end
      end
    end
  end
end
