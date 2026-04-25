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
                arguments: {
                  'x-queue-type':  'classic',
                  'x-expires':     604_800_000,
                  'x-message-ttl': 86_400_000,
                  'x-max-length':  1000
                } }
            end
          end
        end
      end
    end
  end
end
