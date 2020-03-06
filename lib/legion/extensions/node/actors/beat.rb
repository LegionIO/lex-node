module Legion::Extensions::Node::Actor
  class Beat < Legion::Extensions::Actors::Every
    def runner_function
      'beat'
    end

    def use_runner
      false
    end

    def run_now?
      true
    end

    def time
      1
    end
  end
end
