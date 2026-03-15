# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Transport
        module Messages
          class Beat < Legion::Transport::Message
            def routing_key
              'status'
            end

            def type
              'heartbeat'
            end

            def expiration
              5000
            end

            def encrypt?
              false
            end

            def message
              hash = { name: Legion::Settings[:client][:hostname], pid: ::Process.pid, timestamp: Time.now }
              hash[:status] = @options[:status].nil? ? 'healthy' : @options[:status]
              hash
            end

            def validate
              raise 'status should be a string' unless @options[:status].is_a?(String) || @options[:status].nil?

              @valid = true
            end
          end
        end
      end
    end
  end
end
