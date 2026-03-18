# frozen_string_literal: true

require 'base64'

module Legion
  module Extensions
    module Node
      module Transport
        module Messages
          class RequestVaultToken < Legion::Transport::Message
            def routing_key
              'vault'
            end

            def message
              {
                function:     'push_vault_token',
                node_name:    Legion::Settings[:client][:name],
                runner_class: 'Legion::Extensions::Node::Runners::Vault',
                public_key:   Base64.encode64(Legion::Crypt.public_key.to_s)
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
      end
    end
  end
end
