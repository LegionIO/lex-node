# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Runners
        module Beat
          include Legion::Extensions::Helpers::Transport

          def beat(status: 'active', **opts)
            log.debug 'sending hearbeat'
            messages::Beat.new(status: status).publish
            { success: true, status: status, version: Legion::VERSION || nil, **opts }
          end

          include Legion::Extensions::Helpers::Lex
        end
      end
    end
  end
end
