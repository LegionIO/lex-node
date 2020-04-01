module Legion::Extensions::Node::Actor
  class Crypt < Legion::Extensions::Actors::Subscription
    def delay_start
      2
    end

    def runner_class
      Legion::Extensions::Node::Actor::Crypt
    end
  end
end
