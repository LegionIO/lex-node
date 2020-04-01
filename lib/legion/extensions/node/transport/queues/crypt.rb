module Legion::Extensions::Node::Transport::Queues
  class Crypt < Legion::Transport::Queue
    def queue_options
      { auto_delete: false }
    end
  end
end
