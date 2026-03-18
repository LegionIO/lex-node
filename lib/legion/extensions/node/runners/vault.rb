# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Runners
        module Vault
          def request_token(**)
            return {} if Legion::Settings[:crypt][:vault][:connected]
            return {} unless Legion::Settings[:crypt][:vault][:enabled]

            request_vault_token
          end

          def request_vault_token(**)
            Legion::Extensions::Node::Transport::Messages::RequestVaultToken.new.publish
            {}
          end

          def receive_vault_token(message: nil, token: nil, cluster_name: nil, **opts)
            return { success: false, already_connected: true } if Legion::Settings[:crypt][:vault][:connected]

            token ||= Legion::Crypt.decrypt_from_keypair(message: message)
            clusters = Legion::Settings[:crypt][:vault][:clusters]
            if cluster_name && clusters.is_a?(Hash) && clusters[cluster_name.to_sym]
              clusters[cluster_name.to_sym][:token] = token
              clusters[cluster_name.to_sym][:connected] = true
              return { success: true }
            end

            Legion::Settings[:crypt][:vault][:token] = token
            %i[protocol address port].each do |setting|
              next unless opts.key? setting
              next unless Legion::Settings[:crypt][:vault][setting].nil?

              Legion::Settings[:crypt][:vault][setting] = opts[setting]
            end
            Legion::Crypt.connect_vault
            {}
          end

          def push_vault_token(public_key:, node_name:, **)
            return {} unless Legion::Settings[:crypt][:vault][:token]

            encrypted = Legion::Crypt.encrypt_from_keypair(message: Legion::Settings[:crypt][:vault][:token],
                                                           pub_key: public_key)
            Legion::Extensions::Node::Transport::Messages::PushVaultToken.new(token: encrypted, queue_name: node_name).publish
            {}
          end

          include Legion::Extensions::Helpers::Lex
        end
      end
    end
  end
end
