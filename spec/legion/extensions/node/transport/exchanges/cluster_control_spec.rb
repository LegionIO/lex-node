# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/node/transport/exchanges/cluster_control'

RSpec.describe Legion::Extensions::Node::Transport::Exchanges::ClusterControl do
  describe 'constants' do
    it 'has the correct exchange name' do
      expect(described_class::EXCHANGE_NAME).to eq('legion.cluster.control')
    end

    it 'uses topic exchange type' do
      expect(described_class::EXCHANGE_TYPE).to eq(:topic)
    end

    it 'is durable' do
      expect(described_class::EXCHANGE_OPTIONS).to include(durable: true)
    end

    it 'options are frozen' do
      expect(described_class::EXCHANGE_OPTIONS).to be_frozen
    end
  end
end
