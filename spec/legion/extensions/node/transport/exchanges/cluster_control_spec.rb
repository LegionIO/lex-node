# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/node/transport/exchanges/cluster_control'

RSpec.describe Legion::Extensions::Node::Transport::Exchanges::ClusterControl do
  it 'inherits from Legion::Transport::Exchange' do
    expect(described_class).to be < Legion::Transport::Exchange
  end

  describe 'instance methods' do
    let(:instance) { described_class.allocate }

    it 'has the correct exchange name' do
      expect(instance.exchange_name).to eq('legion.cluster.control')
    end

    it 'uses topic exchange type' do
      expect(instance.default_type).to eq('topic')
    end
  end
end
