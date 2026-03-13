# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Transport
        module Queues
          class Crypt < Legion::Transport::Queue
            def queue_options
              { auto_delete: false }
            end
          end
        end
      end
    end
  end
end
