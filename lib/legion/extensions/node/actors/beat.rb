module Legion::Extensions::Node::Actor
  class Beat < Legion::Extensions::Actors::Every
    def action
      'beat'
    end

    def time
      1
    end
  end
end
