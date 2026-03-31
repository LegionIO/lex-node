# frozen_string_literal: true

module Legion
  module Extensions
    module Node
      module Transport
        module Exchanges
          class ClusterControl
            EXCHANGE_NAME = 'legion.cluster.control'
            EXCHANGE_TYPE = :topic
            EXCHANGE_OPTIONS = { durable: true }.freeze
          end
        end
      end
    end
  end
end
