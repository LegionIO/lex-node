# frozen_string_literal: true

require 'legion/extensions/transport'

module Legion
  module Extensions
    module Node
      module Transport
        extend Legion::Extensions::Transport

        def self.additional_e_to_q
          array = [{ from: 'node', to: 'node', routing_key: "node.#{Legion::Settings[:client][:name]}" }]
          array.push(from: 'node', to: 'node', routing_key: 'node.data.#') if Legion::Settings[:data][:connected]
          array.push(from: 'node', to: 'node', routing_key: 'node.cache.#') if Legion::Settings[:cache][:connected]
          array.push(from: 'node', to: 'node', routing_key: 'node.crypt.#')
          array
        end
      end
    end
  end
end
