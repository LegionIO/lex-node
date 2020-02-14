module Legion::Extensions::Node::Runners
  module Beat
    def self.beat(status: 'healthy', **opts)
      Legion::Extensions::Node::Transport::Messages::Beat.new(status: status).publish
      { success: true, status: status, **opts }
    end
  end
end
