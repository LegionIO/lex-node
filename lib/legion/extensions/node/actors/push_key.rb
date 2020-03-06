module Legion::Extensions::Node::Actor
  class PushKey < Legion::Extensions::Actors::Once
    def function
      'request_public_keys'
    end

    def runner_class
      Legion::Extensions::Node::Runners::Crypt
    end

    def disabled?
      false
    end
  end
end
