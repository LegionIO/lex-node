require 'legion/transport/exchanges/node'

module Legion::Extensions::Node
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
