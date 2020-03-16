module Legion::Extensions::Node::Actor
  class PushKey < Legion::Extensions::Actors::Once
    def function
      'request_public_keys'
    end

    def runner_class
      Legion::Extensions::Node::Runners::Crypt
    end

    def disabled?
      true
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
