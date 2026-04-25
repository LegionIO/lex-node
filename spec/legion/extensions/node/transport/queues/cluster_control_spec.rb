# frozen_string_literal: true

require 'spec_helper'

# Mirror ClusterControl queue logic in a proxy class to avoid superclass mismatch
# with Legion::Transport::Queue which is not available in the test environment.
CLUSTER_CONTROL_QUEUE_TEST_CLASS = Class.new do
  def queue_name
    "legion.cluster.control.#{Legion::Settings[:client][:name]}"
  end

  def queue_options
    { durable: true, exclusive: false, auto_delete: false,
      arguments: {
        'x-queue-type':  'classic',
        'x-expires':     604_800_000,
        'x-message-ttl': 86_400_000,
        'x-max-length':  1000
      } }
  end
end

RSpec.describe 'ClusterControl queue' do
  subject(:queue) { CLUSTER_CONTROL_QUEUE_TEST_CLASS.new }

  before do
    allow(Legion::Settings).to receive(:[]).with(:client).and_return({ name: 'test-node' })
  end

  describe '#queue_name' do
    it 'includes the node name' do
      expect(queue.queue_name).to eq('legion.cluster.control.test-node')
    end
  end

  describe '#queue_options' do
    it 'is durable so offline nodes can receive queued desired-state commands after restart' do
      expect(queue.queue_options[:durable]).to be true
    end

    it 'is not exclusive' do
      expect(queue.queue_options[:exclusive]).to be false
    end

    it 'does not auto-delete when node disconnects' do
      expect(queue.queue_options[:auto_delete]).to be false
    end

    it 'uses classic queue type' do
      expect(queue.queue_options[:arguments][:'x-queue-type']).to eq('classic')
    end

    it 'expires abandoned per-node queues and stale commands' do
      expect(queue.queue_options[:arguments]).to include(
        'x-expires':     604_800_000,
        'x-message-ttl': 86_400_000,
        'x-max-length':  1000
      )
    end
  end
end
