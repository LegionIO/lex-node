module Legion::Extensions::Node::Transport::Messages
  class PushClusterSecret < Legion::Transport::Message
    def routing_key
      @options[:queue_name]
    end

    def exchange
      Legion::Transport::Exchanges::Node
    end

    def message
      { function:          'receive_cluster_secret',
        runner_class:      'Legion::Extensions::Node::Runners::Crypt',
        message:           @options[:message],
        validation_string: @options[:validation_string] || nil,
        encrypted_string:  @options[:encrypted_string] || nil,
        public_key:        Base64.encode64(Legion::Crypt.public_key) }
    end

    def type
      'task'
    end

    def encrypt?
      false
    end

    def validate
      @valid = true
    end
  end
end
