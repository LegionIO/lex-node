module Legion::Extensions::Node::Transport::Messages
  class RequestVaultToken < Legion::Transport::Message
    def routing_key
      'vault'
    end

    def message
      {
        function: 'push_vault_token',
        node_name: Legion::Settings[:client][:name],
        runner_class: 'Legion::Extensions::Node::Runners::Vault',
        public_key: Legion::Crypt.public_key
      }
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
