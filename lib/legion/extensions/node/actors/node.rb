module Legion::Extensions::Node::Actor
  class Node < Legion::Extensions::Actors::Subscription
    def runner_function
      'message'
    end
  end
end
