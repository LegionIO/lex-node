module Legion::Extensions::Node::Transport::Messages
  class RequestClusterSecret < Legion::Transport::Message
    def routing_key
      'node.crypt.push_cluster_secret'
    end

    def message
      { function: 'push_cluster_secret', node_name: Legion::Settings[:client][:name] }
    end

    def type
      'task'
    end

    def validate
      @valid = true
    end
  end
end
