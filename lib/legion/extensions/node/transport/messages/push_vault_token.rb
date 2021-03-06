module Legion::Extensions::Node::Transport::Messages
  class PushVaultToken < Legion::Transport::Message
    def routing_key
      "node.#{@options[:queue_name]}"
    end

    def exchange
      Legion::Transport::Exchanges::Node
    end

    def message
        {
          function: 'receive_vault_token',
          runner_class: 'Legion::Extensions::Node::Runners::Vault',
          message: @options[:token],
          public_key: Base64.encode64(Legion::Crypt.public_key)
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
