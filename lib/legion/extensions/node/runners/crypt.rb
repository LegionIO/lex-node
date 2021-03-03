module Legion::Extensions::Node::Runners
  module Crypt
    def push_public_key(**_opts)
      log.debug 'push_public_key'
      message_hash = { function: 'update_public_key',
                       public_key: Base64.encode64(Legion::Crypt.public_key),
                       **Legion::Settings[:client] }
      Legion::Extensions::Node::Transport::Messages::PublicKey.new(message_hash).publish
      {}
    end

    def self.update_public_key(name:, public_key:, **_opts)
      log.debug 'update_public_key'
      Legion::Settings[:cluster][:public_keys][name] = public_key
      {}
    end

    def delete_public_key(name:, **_opts)
      log.debug 'delete_public_key'
      Legion::Settings[:cluster][:public_keys].delete(name)
      {}
    end

    def request_public_keys(**_opts)
      log.debug 'request_public_keys'
      message_hash = { function: 'push_public_key' }
      Legion::Extensions::Node::Transport::Messages::RequestPublicKeys.new(**message_hash).publish
      {}
    end

    def request_cluster_secret(**_opts)
      log.debug 'request_cluster_secret'
      Legion::Transport::Messages::RequestClusterSecret.new.publish
      {}
    end

    def push_cluster_secret(public_key:, queue_name:, **_opts)
      log.debug 'push_cluster_secret'
      return {} unless Legion::Settings[:crypt][:cs_encrypt_ready]

      encrypted = Legion::Crypt.encrypt_from_keypair(pub_key: public_key,
                                                     message: Legion::Settings[:crypt][:cluster_secret].to_s)
      legion = Legion::Crypt.encrypt('legion')
      Legion::Extensions::Node::Transport::Messages::PushClusterSecret.new(message: encrypted,
                                                                           queue_name: queue_name,
                                                                           validation_string: 'legion',
                                                                           encrypted_string: legion).publish
      {}
    end

    def receive_cluster_secret(message:, **opts)
      log.debug 'receive_cluster_secret'
      Legion::Settings[:crypt][:cluster_secret] = Legion::Crypt.decrypt_from_keypair(message)
      Legion::Settings[:crypt][:encrypted_string] = opts[:encrypted_string]
      Legion::Settings[:crypt][:validation_string] = opts[:validation_string]
      {}
    end

    include Legion::Extensions::Helpers::Lex
  end
end
