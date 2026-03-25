# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Actor
        class Crypt < Legion::Extensions::Actors::Subscription
          def runner_class = Legion::Extensions::Node::Runners::Node

          def delay_start
            2
          end
        end
      end
    end
  end
end
