module Legion::Extensions::Node::Actor
  class Beat < Legion::Extensions::Actors::Every
    def runner_function
      'beat'
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

    def run_now?
      true
    end

    def time
      1
    end
  end
end
