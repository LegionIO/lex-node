module Legion::Extensions::Node::Runners
  module Beat
    include Legion::Extensions::Helpers::Transport

    def beat(status: 'healthy', **opts)
      log.debug 'sending hearbeat'
      messages::Beat.new(status: status).publish
      { success: true, status: status, **opts }
    end

    include Legion::Extensions::Helpers::Lex
  end
end
