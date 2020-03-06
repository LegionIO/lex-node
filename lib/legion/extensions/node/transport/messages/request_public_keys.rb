module Legion::Extensions::Node::Transport::Messages
  class RequestPublicKeys < Legion::Transport::Message
    def routing_key
      'node'
    end

    def type
      'task'
    end

    def validate
      @valid = true
    end
  end
end
