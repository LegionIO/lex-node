module Legion::Extensions::Node::Transport::Messages
  class Beat < Legion::Transport::Message
    def routing_key
      'health'
    end

    def type
      'heartbeat'
    end

    def expiration
      5000
    end

    def message
      hash = { hostname: Socket.gethostname, pid: Process.pid, timestamp: Time.now }
      hash[:status] = @options[:status].nil? ? 'healthy' : @options[:status]
      hash
    end

    def validate
      raise 'status should be a string' unless @options[:status].is_a?(String) || @options[:status].nil?

      @valid = true
    end
  end
end
