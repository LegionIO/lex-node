require 'legion/extensions/transport/autobuild'

module Legion::Extensions::Node::Transport
  module AutoBuild
    extend Legion::Extensions::Transport::AutoBuild

    def self.additional_e_to_q
      array = [{ from: 'node', to: 'node', routing_key: "node.#{Legion::Settings['client']['name']}" }]
      array.push(from: 'node', to: 'node', routing_key: 'node.data') if Legion::Settings[:data][:connected]
      array.push(from: 'node', to: 'node', routing_key: 'node.cache') if Legion::Settings[:cache][:connected]
      array
    end
  end
end
