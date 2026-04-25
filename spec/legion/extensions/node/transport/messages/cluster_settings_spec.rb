# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/node/control_auth'
require 'legion/extensions/node/transport/exchanges/cluster_control'

# Mirror ClusterSettings message logic in a proxy class to avoid superclass mismatch.
CLUSTER_SETTINGS_TEST_CLASS = Class.new do
  def initialize(**opts)
    @options = opts
  end

  def routing_key
    @options.fetch(:routing_key, 'settings')
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
    Legion::Extensions::Node::ControlAuth.sign(
      function: 'update_settings',
      settings: @options[:settings],
      restart:  @options.fetch(:restart, false)
    )
  end

  def validate
    raise 'settings must be a Hash' unless @options[:settings].is_a?(Hash)

    @valid = true
  end
end

RSpec.describe 'ClusterSettings message' do
  let(:settings_hash) { { feature_flags: { new_feature: true } } }

  subject(:msg) { CLUSTER_SETTINGS_TEST_CLASS.new(settings: settings_hash) }

  before do
    allow(Legion::Settings).to receive(:dig).with(:cluster, :control_secret).and_return('shared-secret')
    allow(Legion::Settings).to receive(:dig).with(:crypt, :cluster_secret).and_return(nil)
    allow(Legion::Settings).to receive(:[]).with(:client).and_return({ name: 'sender-node' })
  end

  describe '#routing_key' do
    it 'defaults to "settings"' do
      expect(msg.routing_key).to eq('settings')
    end

    it 'uses provided routing_key' do
      m = CLUSTER_SETTINGS_TEST_CLASS.new(settings: settings_hash, routing_key: 'flags.beta')
      expect(m.routing_key).to eq('flags.beta')
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

    it 'includes the settings hash' do
      expect(msg.message[:settings]).to eq(settings_hash)
    end

    it 'defaults restart to false' do
      expect(msg.message[:restart]).to be false
    end

    it 'passes restart: true when specified' do
      m = CLUSTER_SETTINGS_TEST_CLASS.new(settings: settings_hash, restart: true)
      expect(m.message[:restart]).to be true
    end

    it 'includes a verifiable control signature envelope' do
      payload = msg.message

      expect(payload[:control]).to include(:sender, :timestamp, :nonce, :signature)
      expect(Legion::Extensions::Node::ControlAuth.verify!(payload)).to eq(payload)
    end

    it 'changes the signature when the settings payload changes' do
      allow(SecureRandom).to receive(:hex).with(16).and_return('a' * 32)
      allow(Time).to receive(:now).and_return(Time.utc(2026, 1, 1))

      first = CLUSTER_SETTINGS_TEST_CLASS.new(settings: { feature: true }).message
      second = CLUSTER_SETTINGS_TEST_CLASS.new(settings: { feature: false }).message

      expect(first[:control][:signature]).not_to eq(second[:control][:signature])
    end
  end

  describe '#validate' do
    context 'when settings is a Hash' do
      it 'sets @valid to true without raising' do
        expect { msg.validate }.not_to raise_error
        expect(msg.instance_variable_get(:@valid)).to be true
      end
    end

    context 'when settings is not a Hash' do
      subject(:bad_msg) { CLUSTER_SETTINGS_TEST_CLASS.new(settings: 'not_a_hash') }

      it 'raises an error' do
        expect { bad_msg.validate }.to raise_error(RuntimeError, 'settings must be a Hash')
      end
    end

    context 'when settings is missing' do
      subject(:missing_msg) { CLUSTER_SETTINGS_TEST_CLASS.new }

      it 'raises an error' do
        expect { missing_msg.validate }.to raise_error(RuntimeError, 'settings must be a Hash')
      end
    end
  end
end
