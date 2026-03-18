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
          unless defined?(Legion::Extensions::Node::Transport::Messages::PublicKey)
            class PublicKey
              def initialize(**); end
              def publish; end
            end
          end

          unless defined?(Legion::Extensions::Node::Transport::Messages::PushClusterSecret)
            class PushClusterSecret
              def initialize(**); end
              def publish; end
            end
          end

          unless defined?(Legion::Extensions::Node::Transport::Messages::RequestPublicKeys)
            class RequestPublicKeys
              def initialize(**); end
              def publish; end
            end
          end

          unless defined?(Legion::Extensions::Node::Transport::Messages::RequestClusterSecret)
            class RequestClusterSecret
              def initialize; end
              def publish; end
            end
          end

          unless defined?(Legion::Extensions::Node::Transport::Messages::UpdateResult)
            class UpdateResult
              def initialize(**); end
              def publish; end
            end
          end
        end
      end

      module Runners
        unless defined?(Legion::Extensions::Node::Runners::Vault)
          module Vault
            def self.receive_vault_token(**opts) = opts
          end
        end
      end
    end
  end

  unless defined?(Legion::Settings)
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

  unless defined?(Legion::Crypt)
    module Crypt
      def self.public_key = 'FAKEPUBKEY' unless method_defined?(:public_key)
      def self.encrypt_from_keypair(**) = 'ENCRYPTED' unless method_defined?(:encrypt_from_keypair)
      def self.encrypt(_) = 'ENCRYPTED_LEGION' unless method_defined?(:encrypt)
      def self.decrypt_from_keypair(message:) = 'DECRYPTED_SECRET' unless method_defined?(:decrypt_from_keypair) # rubocop:disable Lint/UnusedMethodArgument
    end
  end

  unless defined?(Legion::Logging)
    module Logging
      def self.debug(*); end
    end
  end

  def self.reload; end unless respond_to?(:reload)
end

require 'legion/extensions/node/runners/node'

RSpec.describe Legion::Extensions::Node::Runners::Node do
  let(:runner) do
    klass = Class.new do
      include Legion::Extensions::Node::Runners::Node

      def log
        @log ||= Class.new do
          def debug(*); end
          def error(*); end
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

    it 'includes the base64-encoded public key in the message' do
      require 'base64'
      expect(Legion::Extensions::Node::Transport::Messages::PublicKey).to receive(:new) do |args|
        expect(args[:public_key]).to eq(Base64.encode64('FAKEPUBKEY'))
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
          cluster_secret:   'SECRET'
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

    it 'stores encrypted_string from opts' do
      allow(Legion::Crypt).to receive(:decrypt_from_keypair).and_return('DECRYPTED_SECRET')
      crypt_settings = {}
      @settings_store[:crypt] = crypt_settings
      runner.receive_cluster_secret(message: 'ENCRYPTED_MSG', encrypted_string: 'ENC_LEG')
      expect(crypt_settings[:encrypted_string]).to eq('ENC_LEG')
    end

    it 'stores validation_string from opts' do
      allow(Legion::Crypt).to receive(:decrypt_from_keypair).and_return('DECRYPTED_SECRET')
      crypt_settings = {}
      @settings_store[:crypt] = crypt_settings
      runner.receive_cluster_secret(message: 'ENCRYPTED_MSG', validation_string: 'legion')
      expect(crypt_settings[:validation_string]).to eq('legion')
    end

    it 'returns an empty hash' do
      @settings_store[:crypt] = {}
      result = runner.receive_cluster_secret(message: 'ENCRYPTED_MSG')
      expect(result).to eq({})
    end
  end

  describe '#delete_public_key' do
    it 'removes the key from cluster.public_keys' do
      cluster_keys = { 'node-b' => 'PUBKEY_B' }
      @settings_store[:cluster] = { public_keys: cluster_keys }
      runner.delete_public_key(name: 'node-b')
      expect(cluster_keys).not_to have_key('node-b')
    end

    it 'returns an empty hash' do
      @settings_store[:cluster] = { public_keys: {} }
      expect(runner.delete_public_key(name: 'missing')).to eq({})
    end
  end

  describe '#request_public_keys' do
    it 'publishes a RequestPublicKeys message' do
      msg = instance_double(Legion::Extensions::Node::Transport::Messages::RequestPublicKeys, publish: nil)
      expect(Legion::Extensions::Node::Transport::Messages::RequestPublicKeys).to receive(:new).and_return(msg)
      runner.request_public_keys
    end

    it 'returns an empty hash' do
      allow(Legion::Extensions::Node::Transport::Messages::RequestPublicKeys).to receive(:new).and_return(
        instance_double(Legion::Extensions::Node::Transport::Messages::RequestPublicKeys, publish: nil)
      )
      expect(runner.request_public_keys).to eq({})
    end
  end

  describe '#request_cluster_secret' do
    it 'publishes a RequestClusterSecret message' do
      msg = instance_double(Legion::Extensions::Node::Transport::Messages::RequestClusterSecret, publish: nil)
      expect(Legion::Extensions::Node::Transport::Messages::RequestClusterSecret).to receive(:new).and_return(msg)
      runner.request_cluster_secret
    end

    it 'returns an empty hash' do
      allow(Legion::Extensions::Node::Transport::Messages::RequestClusterSecret).to receive(:new).and_return(
        instance_double(Legion::Extensions::Node::Transport::Messages::RequestClusterSecret, publish: nil)
      )
      expect(runner.request_cluster_secret).to eq({})
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

  describe '#update_gem' do
    before do
      @settings_store[:client] = { name: 'test-node' }
      allow(Gem).to receive(:install)
      allow(Legion).to receive(:reload)
      allow(Legion::Extensions::Node::Transport::Messages::UpdateResult).to receive(:new).and_return(
        instance_double(Legion::Extensions::Node::Transport::Messages::UpdateResult, publish: nil)
      )
    end

    it 'calls Gem.install with the normalized extension name and version' do
      runner.update_gem(extension: 'github', version: '0.3.0')
      expect(Gem).to have_received(:install).with('lex-github', '0.3.0')
    end

    it 'normalizes extension name that already has lex- prefix' do
      runner.update_gem(extension: 'lex-github', version: '0.3.0')
      expect(Gem).to have_received(:install).with('lex-github', '0.3.0')
    end

    it 'passes nil version for latest' do
      runner.update_gem(extension: 'github')
      expect(Gem).to have_received(:install).with('lex-github', nil)
    end

    it 'calls Legion.reload when reload is true' do
      runner.update_gem(extension: 'github', reload: true)
      expect(Legion).to have_received(:reload)
    end

    it 'does not call Legion.reload when reload is false' do
      runner.update_gem(extension: 'github', reload: false)
      expect(Legion).not_to have_received(:reload)
    end

    it 'publishes a success result message' do
      expect(Legion::Extensions::Node::Transport::Messages::UpdateResult).to receive(:new).with(
        hash_including(action: 'update_gem', status: 'success')
      ).and_return(instance_double(Legion::Extensions::Node::Transport::Messages::UpdateResult, publish: nil))
      runner.update_gem(extension: 'github', version: '0.3.0')
    end

    context 'when Gem.install raises an error' do
      before { allow(Gem).to receive(:install).and_raise(Gem::InstallError, 'network timeout') }

      it 'does not crash' do
        expect { runner.update_gem(extension: 'github') }.not_to raise_error
      end

      it 'does not call Legion.reload' do
        runner.update_gem(extension: 'github')
        expect(Legion).not_to have_received(:reload)
      end

      it 'publishes a failure result message' do
        expect(Legion::Extensions::Node::Transport::Messages::UpdateResult).to receive(:new).with(
          hash_including(action: 'update_gem', status: 'failed', error: 'network timeout')
        ).and_return(instance_double(Legion::Extensions::Node::Transport::Messages::UpdateResult, publish: nil))
        runner.update_gem(extension: 'github')
      end
    end
  end

  describe '#update_settings' do
    before do
      @settings_store[:client] = { name: 'test-node' }
      @settings_store[:transport] = { host: 'old-host', port: 5672 }
      allow(Legion).to receive(:reload)
      allow(Legion::Extensions::Node::Transport::Messages::UpdateResult).to receive(:new).and_return(
        instance_double(Legion::Extensions::Node::Transport::Messages::UpdateResult, publish: nil)
      )
    end

    it 'deep-merges settings into Legion::Settings' do
      runner.update_settings(settings: { transport: { host: 'new-host' } })
      expect(@settings_store[:transport][:host]).to eq('new-host')
    end

    it 'preserves existing keys not in the update' do
      runner.update_settings(settings: { transport: { host: 'new-host' } })
      expect(@settings_store[:transport][:port]).to eq(5672)
    end

    it 'does not call Legion.reload by default' do
      runner.update_settings(settings: { transport: { host: 'new-host' } })
      expect(Legion).not_to have_received(:reload)
    end

    it 'calls Legion.reload when restart is true' do
      runner.update_settings(settings: { transport: { host: 'new-host' } }, restart: true)
      expect(Legion).to have_received(:reload)
    end

    it 'publishes a success result message' do
      expect(Legion::Extensions::Node::Transport::Messages::UpdateResult).to receive(:new).with(
        hash_including(action: 'update_settings', status: 'success')
      ).and_return(instance_double(Legion::Extensions::Node::Transport::Messages::UpdateResult, publish: nil))
      runner.update_settings(settings: { transport: { host: 'new-host' } })
    end

    context 'when merge fails' do
      it 'publishes a failure result and does not crash' do
        allow(Legion::Settings).to receive(:[]).with(:bad_key).and_return(nil)
        expect(Legion::Extensions::Node::Transport::Messages::UpdateResult).to receive(:new).with(
          hash_including(action: 'update_settings', status: 'failed')
        ).and_return(instance_double(Legion::Extensions::Node::Transport::Messages::UpdateResult, publish: nil))
        expect { runner.update_settings(settings: { bad_key: { nested: 'val' } }) }.not_to raise_error
      end
    end
  end
end
