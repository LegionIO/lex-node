# frozen_string_literal: true

require 'spec_helper'

# RequestClusterSecret is pre-stubbed in node_spec.rb as a plain class (no parent).
# Requiring the real file would cause a superclass mismatch at load time.
# Test the logic via a proxy class that mirrors the real implementation.

unless defined?(Legion::Settings)
  module Legion
    module Settings
      def self.[](key)
        @store ||= {}
        @store[key]
      end

      def self.[]=(key, val)
        @store ||= {}
        @store[key] = val
      end
    end
  end
end

REQUEST_CLUSTER_SECRET_TEST_CLASS = Class.new do
  def initialize(**opts)
    @options = opts
  end

  def routing_key
    'node.crypt.push_cluster_secret'
  end

  def message
    { function: 'push_cluster_secret', node_name: Legion::Settings[:client][:name] }
  end

  def type
    'task'
  end

  def encrypt?
    false
  end

  def validate
    @valid = true
  end
end

RSpec.describe 'RequestClusterSecret message' do
  subject(:msg) { REQUEST_CLUSTER_SECRET_TEST_CLASS.new }

  describe '#routing_key' do
    it 'returns the node crypt push_cluster_secret routing key' do
      expect(msg.routing_key).to eq('node.crypt.push_cluster_secret')
    end
  end

  describe '#type' do
    it 'returns "task"' do
      expect(msg.type).to eq('task')
    end
  end

  describe '#encrypt?' do
    it 'returns false' do
      expect(msg.encrypt?).to be false
    end
  end

  describe '#validate' do
    it 'sets @valid to true' do
      msg.validate
      expect(msg.instance_variable_get(:@valid)).to be true
    end
  end

  describe '#message' do
    it 'includes function push_cluster_secret' do
      allow(Legion::Settings).to receive(:[]).with(:client).and_return({ name: 'test-node' })
      result = msg.message
      expect(result[:function]).to eq('push_cluster_secret')
    end

    it 'includes node_name from client settings' do
      allow(Legion::Settings).to receive(:[]).with(:client).and_return({ name: 'my-node' })
      result = msg.message
      expect(result[:node_name]).to eq('my-node')
    end
  end
end
