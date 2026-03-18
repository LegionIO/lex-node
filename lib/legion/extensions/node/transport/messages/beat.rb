# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Transport
        module Messages
          class Beat < Legion::Transport::Message
            BOOT_TIME = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
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
              hash = {
                name:      Legion::Settings[:client][:name],
                pid:       ::Process.pid,
                timestamp: Time.now,
                status:    @options[:status].nil? ? 'healthy' : @options[:status]
              }
              hash[:version] = Legion::VERSION if defined?(Legion::VERSION)
              hash[:metrics] = collect_metrics
              hash[:hosted_worker_ids] = collect_worker_ids
              hash
            end

            def validate
              raise 'status should be a string' unless @options[:status].is_a?(String) || @options[:status].nil?

              @valid = true
            end

            private

            def collect_metrics
              times = ::Process.times
              {
                memory_rss_mb:      rss_mb,
                cpu_user_seconds:   times.utime.round(2),
                cpu_system_seconds: times.stime.round(2),
                thread_count:       Thread.list.count,
                loaded_extensions:  loaded_extension_count,
                uptime_seconds:     uptime_seconds
              }
            end

            def rss_mb
              if RUBY_PLATFORM.include?('darwin')
                `ps -o rss= -p #{::Process.pid}`.strip.to_i / 1024.0
              else
                File.read("/proc/#{::Process.pid}/statm").split[1].to_i * (4096.0 / 1_048_576)
              end
            rescue StandardError
              0.0
            end

            def loaded_extension_count
              return 0 unless defined?(Legion::Extensions)

              Legion::Extensions.respond_to?(:loaded_extensions) ? Legion::Extensions.loaded_extensions.count : 0
            end

            def uptime_seconds
              (::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - BOOT_TIME).round(0)
            end

            def collect_worker_ids
              return [] unless defined?(Legion::DigitalWorker)

              Legion::DigitalWorker.active_local_ids
            rescue StandardError
              []
            end
          end
        end
      end
    end
  end
end
