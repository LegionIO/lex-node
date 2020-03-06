module Legion::Extensions::Node::Transport::Messages
  class PublicKey < Legion::Transport::Message
    def routing_key
      'node.crypt.update_public_key'
    end

    def type
      'task'
    end

    def validate
      raise 'public_key should be a string'  unless @options[:public_key].is_a?(String)

      @valid = true
    end
  end
end
