# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Transport
        module Exchanges
          class ClusterControl < Legion::Transport::Exchange
            def exchange_name
              'legion.cluster.control'
            end

            def default_type
              'topic'
            end
          end
        end
      end
    end
  end
end
