# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Transport
        module Messages
          class UpdateResult < Legion::Transport::Message
            def routing_key
              "node.#{Legion::Settings[:client][:name]}.update_result"
            end

            def exchange
              Legion::Transport::Exchanges::Node
            end

            def type
              'task'
            end

            def encrypt?
              false
            end

            def validate
              raise 'action is required' unless @options[:action].is_a?(String)
              raise 'status is required' unless @options[:status].is_a?(String)

              @valid = true
            end
          end
        end
      end
    end
  end
end
