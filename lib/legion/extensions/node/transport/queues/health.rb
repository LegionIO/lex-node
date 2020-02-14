module Legion::Extensions::Node::Transport::Queues
  class Health < Legion::Transport::Queue
    def queue_options
      { arguments: { 'x-single-active-consumer': true }, auto_delete: false }
    end
  end
end
