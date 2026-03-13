# frozen_string_literal: true

require 'legion/transport/exchanges/node'

module Legion
  module Extensions
    module Node
      module Transport
        module Exchanges
          class Node < Legion::Transport::Exchanges::Node
            def exchange_name
              'node'
            end
          end
        end
      end
    end
  end
end
