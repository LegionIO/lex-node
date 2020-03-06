module Legion::Extensions::Node::Runners
  module Node
    include Legion::Extensions::Helpers::Lex

    def self.message(_options = {}, **hash)
      log.debug 'message'
      hash.each do |k, v|
        raise 'Cannot override base setting that doesn\'t exist' if Legion::Settings[k].nil?

        if v.is_a? String
          Legion::Settings[k] = v
        elsif v.is_a? Hash
          v.each do |key, value|
            Legion::Settings[k][key] = value
          end
        end
      end
    end

    def self.push_public_key(**opts)
      log.debug 'push_public_key'
      message_hash = { function: 'update_public_key', public_key: Legion::Crypt.public_key.to_s, **Legion::Settings[:client] }
      Legion::Extensions::Node::Transport::Messages::PublicKey.new(message_hash).publish
      { }
    end
    #
    def self.update_public_key(name:, public_key:, **opts)
      log.debug 'update_public_key'
      Legion::Settings[:cluster][:public_keys][name] = public_key
      {}
    end

    def self.receive_cluster_secret(public_key:, message:, **opts)
      log.debug 'receive_cluster_secret'
      Legion::Settings[:crypt][:cluster_secret] = Legion::Crypt.decrypt_from_keypair(public_key: public_key, message: message)
      {}
    end
  end
end
