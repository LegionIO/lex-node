require 'legion/extensions/transport'

module Legion::Extensions::Node::Transport
  extend Legion::Extensions::Transport
  def self.additional_e_to_q
    array = [{ from: 'node', to: 'node', routing_key: "node.#{Legion::Settings[:client][:name]}" }]
    array.push(from: 'node', to: 'node', routing_key: 'node.data.#') if Legion::Settings[:data][:connected]
    array.push(from: 'node', to: 'node', routing_key: 'node.cache.#') if Legion::Settings[:cache][:connected]
    array.push(from: 'node', to: 'node', routing_key: 'node.crypt.#')
    array
  end
end
