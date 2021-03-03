module Legion::Extensions::Node::Transport::Queues
  class Vault < Legion::Transport::Queue
    def queue_options
      { auto_delete: false }
    end
  end
end
