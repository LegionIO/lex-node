# frozen_string_literal: true

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
              { durable: true, exclusive: false, auto_delete: false,
                arguments: { 'x-queue-type': 'classic' } }
            end
          end
        end
      end
    end
  end
end
