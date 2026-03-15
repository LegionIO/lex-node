# frozen_string_literal: true

require 'spec_helper'

# Stub framework dependencies before loading the runner
module Legion
  module Extensions
    module Helpers
      module Lex; end unless defined?(Legion::Extensions::Helpers::Lex)
    end

    module Node
      module Transport
        module Messages
          class PublicKey
            def initialize(**); end
            def publish; end
          end unless defined?(Legion::Extensions::Node::Transport::Messages::PublicKey)

          class PushClusterSecret
            def initialize(**); end
            def publish; end
          end unless defined?(Legion::Extensions::Node::Transport::Messages::PushClusterSecret)
        end
      end

      module Runners
        module Vault
          def self.receive_vault_token(**opts); opts end
        end unless defined?(Legion::Extensions::Node::Runners::Vault)
      end
    end
  end

  module Settings
    def self.[](key); @store ||= {}; @store[key] end
    def self.[]=(key, val); @store ||= {}; @store[key] = val end
  end unless defined?(Legion::Settings)

  module Crypt
    def self.public_key; 'FAKEPUBKEY'; end unless method_defined?(:public_key)
    def self.encrypt_from_keypair(**); 'ENCRYPTED'; end unless method_defined?(:encrypt_from_keypair)
    def self.encrypt(_); 'ENCRYPTED_LEGION'; end unless method_defined?(:encrypt)
    def self.decrypt_from_keypair(message:); 'DECRYPTED_SECRET'; end unless method_defined?(:decrypt_from_keypair)
  end unless defined?(Legion::Crypt)

  module Logging
    def self.debug(*); end
  end unless defined?(Legion::Logging)
end

require 'legion/extensions/node/runners/node'

# rubocop:disable Metrics/BlockLength
RSpec.describe Legion::Extensions::Node::Runners::Node do
  let(:runner) do
    klass = Class.new do
      include Legion::Extensions::Node::Runners::Node

      def log
        @log ||= Class.new do
          def debug(*); end
        end.new
      end
    end
    klass.new
  end

  before do
    @settings_store = {}
    allow(Legion::Settings).to receive(:[]) { |k| @settings_store[k] }
    allow(Legion::Settings).to receive(:[]=) { |k, v| @settings_store[k] = v }
  end

  describe '#message' do
    it 'updates a string setting' do
      @settings_store[:transport] = 'old'
      runner.message(transport: 'new_value')
      expect(@settings_store[:transport]).to eq('new_value')
    end

    it 'raises when key does not exist in settings' do
      allow(Legion::Settings).to receive(:[]).and_return(nil)
      expect { runner.message(nonexistent: 'value') }.to raise_error(RuntimeError, /Cannot override base setting/)
    end

    it 'merges hash values into existing setting' do
      @settings_store[:transport] = { host: 'old' }
      runner.message(transport: { host: 'newhost' })
      expect(@settings_store[:transport][:host]).to eq('newhost')
    end
  end

  describe '#push_public_key' do
    before do
      @settings_store[:client] = { name: 'test-node' }
      allow(Legion::Crypt).to receive(:public_key).and_return('FAKEPUBKEY')
      allow(Legion::Extensions::Node::Transport::Messages::PublicKey).to receive(:new).and_return(
        instance_double(Legion::Extensions::Node::Transport::Messages::PublicKey, publish: nil)
      )
    end

    it 'returns an empty hash' do
      result = runner.push_public_key
      expect(result).to eq({})
    end

    it 'publishes a PublicKey message' do
      expect(Legion::Extensions::Node::Transport::Messages::PublicKey).to receive(:new)
      runner.push_public_key
    end

    it 'includes the public key in the message' do
      expect(Legion::Extensions::Node::Transport::Messages::PublicKey).to receive(:new) do |**args|
        expect(args[:public_key]).to eq('FAKEPUBKEY')
        instance_double(Legion::Extensions::Node::Transport::Messages::PublicKey, publish: nil)
      end
      runner.push_public_key
    end
  end

  describe '#update_public_key' do
    it 'stores the public key in settings cluster.public_keys' do
      cluster_keys = {}
      @settings_store[:cluster] = { public_keys: cluster_keys }
      runner.update_public_key(name: 'node-b', public_key: 'PUBKEY_B')
      expect(cluster_keys['node-b']).to eq('PUBKEY_B')
    end

    it 'returns an empty hash' do
      @settings_store[:cluster] = { public_keys: {} }
      result = runner.update_public_key(name: 'n', public_key: 'k')
      expect(result).to eq({})
    end
  end

  describe '#push_cluster_secret' do
    context 'when cs_encrypt_ready is false' do
      it 'returns empty hash without publishing' do
        @settings_store[:crypt] = { cs_encrypt_ready: false }
        expect(Legion::Extensions::Node::Transport::Messages::PushClusterSecret).not_to receive(:new)
        result = runner.push_cluster_secret(public_key: 'PK', queue_name: 'node-b')
        expect(result).to eq({})
      end
    end

    context 'when cs_encrypt_ready is true' do
      before do
        @settings_store[:crypt] = {
          cs_encrypt_ready: true,
          cluster_secret: 'SECRET'
        }
        allow(Legion::Crypt).to receive(:encrypt_from_keypair).and_return('ENCRYPTED')
        allow(Legion::Crypt).to receive(:encrypt).and_return('ENCRYPTED_LEGION')
      end

      it 'publishes a PushClusterSecret message' do
        msg = instance_double(Legion::Extensions::Node::Transport::Messages::PushClusterSecret, publish: nil)
        expect(Legion::Extensions::Node::Transport::Messages::PushClusterSecret).to receive(:new).and_return(msg)
        runner.push_cluster_secret(public_key: 'PK', queue_name: 'node-b')
      end

      it 'returns empty hash' do
        msg = instance_double(Legion::Extensions::Node::Transport::Messages::PushClusterSecret, publish: nil)
        allow(Legion::Extensions::Node::Transport::Messages::PushClusterSecret).to receive(:new).and_return(msg)
        result = runner.push_cluster_secret(public_key: 'PK', queue_name: 'node-b')
        expect(result).to eq({})
      end
    end
  end

  describe '#receive_cluster_secret' do
    it 'decrypts and stores the cluster secret' do
      allow(Legion::Crypt).to receive(:decrypt_from_keypair).and_return('DECRYPTED_SECRET')
      crypt_settings = {}
      @settings_store[:crypt] = crypt_settings
      runner.receive_cluster_secret(message: 'ENCRYPTED_MSG')
      expect(crypt_settings[:cluster_secret]).to eq('DECRYPTED_SECRET')
    end

    it 'returns an empty hash' do
      @settings_store[:crypt] = {}
      result = runner.receive_cluster_secret(message: 'ENCRYPTED_MSG')
      expect(result).to eq({})
    end
  end

  describe '#receive_vault_token' do
    it 'delegates to Vault runner' do
      expect(Legion::Extensions::Node::Runners::Vault).to receive(:receive_vault_token).with(
        message: 'ENC', routing_key: 'node.vault', public_key: 'PK'
      )
      runner.receive_vault_token(message: 'ENC', routing_key: 'node.vault', public_key: 'PK')
    end
  end
end
# rubocop:enable Metrics/BlockLength
