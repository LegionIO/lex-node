module Legion::Extensions::Node::Actor
  class Vault < Legion::Extensions::Actors::Subscription
    # def delay_start
    #   2
    # end

    def runner_class
      Legion::Extensions::Node::Runners::Vault
    end

    def disabled?
      false
    end

    def use_runner?
      true
    end

    def check_subtask?
      false
    end

    def generate_task?
      false
    end
  end
end
