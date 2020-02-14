module Legion::Extensions::Node::Actor
  class Test < Legion::Extensions::Actors::Subscription
    def runner_function
      'beat'
    end

    def klass
      Legion::Extensions::Node::Runners::Beat
    end
  end
end
