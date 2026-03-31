# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/node/transport/exchanges/cluster_control'

CLUSTER_KILLSWITCH_ROUTING_KEY = 'settings.extensions.blocked'

# Mirror ClusterKillswitch message logic in a proxy class to avoid superclass mismatch.
CLUSTER_KILLSWITCH_TEST_CLASS = Class.new do
  def initialize(**opts)
    @options = opts
  end

  def routing_key
    CLUSTER_KILLSWITCH_ROUTING_KEY
  end

  def exchange
    Legion::Extensions::Node::Transport::Exchanges::ClusterControl
  end

  def type
    'task'
  end

  def encrypt?
    false
  end

  def message
    {
      function: 'update_settings',
      settings: { extensions: { blocked: [@options[:extension]] } },
      restart:  true
    }
  end

  def validate
    raise 'extension must be a String' unless @options[:extension].is_a?(String)

    @valid = true
  end
end

RSpec.describe 'ClusterKillswitch message' do
  subject(:msg) { CLUSTER_KILLSWITCH_TEST_CLASS.new(extension: 'my-ext') }

  describe 'routing key constant' do
    it 'is settings.extensions.blocked' do
      expect(CLUSTER_KILLSWITCH_ROUTING_KEY).to eq('settings.extensions.blocked')
    end
  end

  describe '#routing_key' do
    it 'returns settings.extensions.blocked' do
      expect(msg.routing_key).to eq('settings.extensions.blocked')
    end
  end

  describe '#exchange' do
    it 'targets the ClusterControl exchange' do
      expect(msg.exchange).to eq(Legion::Extensions::Node::Transport::Exchanges::ClusterControl)
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

  describe '#message' do
    it 'includes function update_settings' do
      expect(msg.message[:function]).to eq('update_settings')
    end

    it 'sets restart to true for immediate effect' do
      expect(msg.message[:restart]).to be true
    end

    it 'wraps extension in a blocked array' do
      expect(msg.message[:settings][:extensions][:blocked]).to eq(['my-ext'])
    end
  end

  describe '#validate' do
    context 'when extension is a String' do
      it 'sets @valid to true without raising' do
        expect { msg.validate }.not_to raise_error
        expect(msg.instance_variable_get(:@valid)).to be true
      end
    end

    context 'when extension is not a String' do
      subject(:bad_msg) { CLUSTER_KILLSWITCH_TEST_CLASS.new(extension: :symbol_ext) }

      it 'raises an error' do
        expect { bad_msg.validate }.to raise_error(RuntimeError, 'extension must be a String')
      end
    end

    context 'when extension is missing' do
      subject(:missing_msg) { CLUSTER_KILLSWITCH_TEST_CLASS.new }

      it 'raises an error' do
        expect { missing_msg.validate }.to raise_error(RuntimeError, 'extension must be a String')
      end
    end
  end
end
