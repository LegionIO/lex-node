module Legion::Extensions::Node::Actor
  class VaultTokenRequest < Legion::Extensions::Actors::Once
    def runner_function
      'request_token'
    end

    def runner_class
      Legion::Extensions::Node::Runners::Vault
    end

    def use_runner?
      false
    end

    def check_subtask?
      false
    end

    def generate_task?
      false
    end

    def delay
      0
    end
  end
end
