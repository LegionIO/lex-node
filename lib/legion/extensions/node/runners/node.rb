module Legion::Extensions::Node::Runners
  module Node
    include Legion::Extensions::Helpers::Lex

    def self.message(_options = {}, **hash)
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

    def self.push_public_key(**_opts)
      log.debug 'push_public_key'
      message_hash = { function: 'update_public_key',
                       public_key: Legion::Crypt.public_key.to_s,
                       **Legion::Settings[:client] }
      Legion::Extensions::Node::Transport::Messages::PublicKey.new(message_hash).publish
      {}
    end

    def self.update_public_key(name:, public_key:, **_opts)
      log.debug 'update_public_key'
      Legion::Settings[:cluster][:public_keys][name] = public_key
      {}
    end

    def self.push_cluster_secret(public_key:, queue_name:, **_opts)
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

    def self.receive_cluster_secret(message:, **_opts)
      log.debug 'receive_cluster_secret'
      Legion::Settings[:crypt][:cluster_secret] = Legion::Crypt.decrypt_from_keypair(message: message)
      {}
    end
  end
end
