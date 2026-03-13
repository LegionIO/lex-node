# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Transport
        module Queues
          class Health < Legion::Transport::Queue
            def queue_options
              { arguments: { 'x-single-active-consumer': true }, auto_delete: false }
            end
          end
        end
      end
    end
  end
end
