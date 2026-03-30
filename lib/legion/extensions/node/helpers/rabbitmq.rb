# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Legion
  module Extensions
    module Node
      module Helpers
        module Rabbitmq
          module_function

          def cluster_health(settings: nil)
            settings ||= resolve_settings
            http = build_http(settings)
            {
              node_count:     fetch_node_count(http, settings),
              quorum_leaders: fetch_quorum_leaders(http, settings),
              shovel_links:   fetch_shovel_links(http, settings)
            }
          rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
            log.warn("RabbitMQ management API unreachable: #{e.message}")
            { node_count: unreachable, quorum_leaders: unreachable, shovel_links: unreachable }
          end

          def fetch_node_count(http, settings)
            body = api_get(http, '/api/nodes', settings)
            return unreachable unless body

            running = body.count { |n| n['running'] }
            total   = body.size
            status  = if running == total
                        'ok'
                      else
                        (running.positive? ? 'warn' : 'critical')
                      end
            { status: status, running: running, total: total }
          end

          def fetch_quorum_leaders(http, settings)
            vhost = settings.dig(:connection, :vhost) || '/'
            encoded_vhost = URI.encode_www_form_component(vhost)
            body = api_get(http, "/api/queues/#{encoded_vhost}", settings)
            return unreachable unless body

            quorum_queues = body.select { |q| q['type'] == 'quorum' }
            return { status: 'ok', quorum_queues: 0, leaders_on_this_node: 0 } if quorum_queues.empty?

            node_name = resolve_node_name(http, settings)
            leaders_here = quorum_queues.count { |q| q['leader'] == node_name }
            { status: 'ok', quorum_queues: quorum_queues.size, leaders_on_this_node: leaders_here }
          end

          def fetch_shovel_links(http, settings)
            vhost = settings.dig(:connection, :vhost) || '/'
            encoded_vhost = URI.encode_www_form_component(vhost)
            body = api_get(http, "/api/shovels/#{encoded_vhost}", settings)
            return unreachable unless body

            running = body.count { |s| s['state'] == 'running' }
            total   = body.size
            status  = if total.zero?
                        'ok'
                      else
                        (running == total ? 'ok' : 'warn')
                      end
            { status: status, total: total, running: running }
          rescue StandardError => _e
            { status: 'ok', total: 0, running: 0 }
          end

          def build_http(settings)
            host = settings.dig(:connection, :host) || '127.0.0.1'
            port = settings[:management_port] || 15_672
            http = Net::HTTP.new(host, port)
            http.open_timeout = 3
            http.read_timeout = 5
            http
          end

          def api_get(http, path, settings)
            req = Net::HTTP::Get.new(path)
            req.basic_auth(
              settings.dig(:connection, :user) || 'guest',
              settings.dig(:connection, :password) || 'guest'
            )
            response = http.request(req)
            return nil unless response.code.start_with?('2')

            ::JSON.parse(response.body)
          rescue StandardError => _e
            nil
          end

          def resolve_node_name(http, settings)
            body = api_get(http, '/api/whoami', settings)
            return nil unless body

            nodes = api_get(http, '/api/nodes', settings)
            return nil unless nodes

            nodes.first&.dig('name')
          end

          def resolve_settings
            return Legion::Settings[:transport].to_h if defined?(Legion::Settings) && Legion::Settings.respond_to?(:[])

            { connection:      { host: '127.0.0.1', user: 'guest', password: 'guest', vhost: '/' },
              management_port: 15_672 }
          end

          def unreachable
            { status: 'unknown', detail: 'management api unreachable' }
          end

          def log_warn(msg)
            log.warn(msg)
          end
        end
      end
    end
  end
end
