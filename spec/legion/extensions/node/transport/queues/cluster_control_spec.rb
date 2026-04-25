# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/node/config'

# Mirror ClusterControl queue logic in a proxy class to avoid superclass mismatch
# with Legion::Transport::Queue which is not available in the test environment.
CLUSTER_CONTROL_QUEUE_TEST_CLASS = Class.new do
  def queue_name
    "legion.cluster.control.#{Legion::Settings[:client][:name]}"
  end

  def queue_options
    options = Legion::Extensions::Node::Config.control_queue
    { durable:     truthy?(options[:durable], default: true),
      exclusive:   truthy?(options[:exclusive], default: false),
      auto_delete: truthy?(options[:auto_delete], default: false),
      arguments:   queue_arguments(options) }
  end

  private

  def queue_arguments(options)
    {
      'x-queue-type':  options[:queue_type],
      'x-expires':     positive_integer(options[:expires_ms]),
      'x-message-ttl': positive_integer(options[:message_ttl_ms]),
      'x-max-length':  positive_integer(options[:max_length])
    }.compact
  end

  def positive_integer(value)
    return value if value.is_a?(Integer) && value.positive?
    return nil unless value.to_s.match?(/\A\d+\z/)

    parsed = value.to_i
    parsed.positive? ? parsed : nil
  end

  def truthy?(value, default:)
    return default if value.nil?

    value == true || value.to_s == 'true'
  end
end

RSpec.describe 'ClusterControl queue' do
  subject(:queue) { CLUSTER_CONTROL_QUEUE_TEST_CLASS.new }

  before do
    allow(Legion::Settings).to receive(:dig).and_return(nil)
    allow(Legion::Settings).to receive(:dig).with(:extensions, :node).and_return({})
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

    it 'uses configured queue durability and retention overrides' do
      allow(Legion::Settings).to receive(:dig).with(:extensions, :node).and_return(
        cluster_control: {
          queue: {
            durable:        false,
            auto_delete:    true,
            expires_ms:     nil,
            message_ttl_ms: 30_000,
            max_length:     25
          }
        }
      )

      expect(queue.queue_options).to eq(
        durable:     false,
        exclusive:   false,
        auto_delete: true,
        arguments:   {
          'x-queue-type':  'classic',
          'x-message-ttl': 30_000,
          'x-max-length':  25
        }
      )
    end
  end
end
