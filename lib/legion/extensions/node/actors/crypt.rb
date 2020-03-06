module Legion::Extensions::Node::Actor
  class Crypt < Legion::Extensions::Actors::Subscription
    def delay_start
      2
    end
  end
end
