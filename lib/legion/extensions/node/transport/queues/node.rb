# frozen_string_literal: true

require 'socket'

module Legion
  module Extensions
    module Node
      module Transport
        module Queues
          class Node < Legion::Transport::Queue
            def queue_name
              "node.#{Legion::Settings[:client][:name]}"
            end

            def queue_options
              { durable: false, exclusive: true, auto_delete: true,
                arguments: { 'x-queue-type': 'classic' } }
            end
          end
        end
      end
    end
  end
end
