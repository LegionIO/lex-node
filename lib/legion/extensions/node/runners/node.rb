# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Runners
        module Node
          def message(_options = {}, **hash)
            log.debug 'message'
            hash.each do |k, v|
              raise 'Cannot override base setting that doesn\'t exist' if Legion::Settings[k].nil?

              case v
              when String
                Legion::Settings[k] = v
              when Hash
                v.each do |key, value|
                  Legion::Settings[k][key] = value
                end
              end
            end
          end

          def update_gem(extension:, version: nil, reload: true, **_opts)
            name = extension.to_s.delete_prefix('lex-')
            gem_name = "lex-#{name}"
            log.debug "update_gem: installing #{gem_name} #{version || 'latest'}"

            Gem.install(gem_name, version)
            Legion.reload if reload

            publish_update_result(action: 'update_gem', status: 'success', detail: "#{gem_name} #{version || 'latest'}")
          rescue StandardError => e
            log.error "update_gem failed: #{e.message}"
            publish_update_result(action: 'update_gem', status: 'failed', detail: gem_name, error: e.message)
          end

          def update_settings(settings:, restart: false, **_opts)
            log.debug "update_settings: merging #{settings.keys.join(', ')}"

            settings.each do |k, v|
              case v
              when Hash
                Legion::Settings[k] ||= {}
                v.each { |key, value| Legion::Settings[k][key] = value }
              else
                Legion::Settings[k] = v
              end
            end

            Legion.reload if restart

            publish_update_result(action: 'update_settings', status: 'success',
                                  detail: "keys: #{settings.keys.join(', ')}")
          rescue StandardError => e
            log.error "update_settings failed: #{e.message}"
            publish_update_result(action: 'update_settings', status: 'failed', error: e.message)
          end

          def push_public_key(**_opts)
            log.debug 'push_public_key'
            message_hash = { function:   'update_public_key',
                             public_key: Legion::Crypt.public_key.to_s,
                             **Legion::Settings[:client] }
            Legion::Extensions::Node::Transport::Messages::PublicKey.new(**message_hash).publish
            {}
          end

          def update_public_key(name:, public_key:, **_opts)
            log.debug 'update_public_key'
            Legion::Settings[:cluster][:public_keys][name] = public_key
            {}
          end

          def push_cluster_secret(public_key:, queue_name:, **_opts)
            log.debug 'push_cluster_secret'
            return {} unless Legion::Settings[:crypt][:cs_encrypt_ready]

            encrypted = Legion::Crypt.encrypt_from_keypair(pub_key: public_key,
                                                           message: Legion::Settings[:crypt][:cluster_secret].to_s)
            legion = Legion::Crypt.encrypt('legion')
            Legion::Extensions::Node::Transport::Messages::PushClusterSecret.new(message:           encrypted,
                                                                                 queue_name:        queue_name,
                                                                                 validation_string: 'legion',
                                                                                 encrypted_string:  legion).publish
            {}
          end

          def receive_cluster_secret(message:, **_opts)
            log.debug 'receive_cluster_secret'
            Legion::Settings[:crypt][:cluster_secret] = Legion::Crypt.decrypt_from_keypair(message: message)
            {}
          end

          def receive_vault_token(message:, routing_key:, public_key:, **)
            Legion::Extensions::Node::Runners::Vault.receive_vault_token(message: message, routing_key: routing_key,
                                                                         public_key: public_key)
          end

          private

          def publish_update_result(action:, status:, detail: nil, error: nil)
            Legion::Extensions::Node::Transport::Messages::UpdateResult.new(
              action:    action,
              status:    status,
              detail:    detail,
              error:     error,
              node:      Legion::Settings[:client][:name],
              timestamp: Time.now.utc.iso8601
            ).publish
          end

          include Legion::Extensions::Helpers::Lex
        end
      end
    end
  end
end
