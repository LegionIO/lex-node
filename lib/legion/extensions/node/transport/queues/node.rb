require 'socket'

module Legion::Extensions::Node::Transport::Queues
  class Node < Legion::Transport::Queue
    def queue_name
      "node.#{Legion::Settings['client']['name']}"
    end

    def queue_options
      { durable: false, exclusive: true, auto_delete: true }
    end
  end
end
