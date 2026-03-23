# frozen_string_literal: true

require 'spec_helper'

module Legion
  module Extensions
    module Helpers
      module Lex; end unless defined?(Legion::Extensions::Helpers::Lex)
    end

    module Node
      module Transport
        module Messages
          unless defined?(RequestVaultToken)
            class RequestVaultToken
              def initialize(**); end
              def publish; end
            end
          end

          unless defined?(PushVaultToken)
            class PushVaultToken
              def initialize(**); end
              def publish; end
            end
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
      def self.decrypt_from_keypair(message:) = 'DECRYPTED_TOKEN' # rubocop:disable Lint/UnusedMethodArgument
      def self.encrypt_from_keypair(**) = 'ENCRYPTED_TOKEN'
      def self.connect_vault; end
    end
  end

  unless defined?(Legion::Logging)
    module Logging
      def self.debug(*); end
    end
  end
end

require 'legion/extensions/node/runners/vault'

RSpec.describe Legion::Extensions::Node::Runners::Vault do
  let(:vault_store) { { connected: false, enabled: true, token: nil, protocol: nil, address: nil, port: nil, clusters: {} } }

  let(:runner) do
    store = vault_store
    klass = Class.new do
      include Legion::Extensions::Node::Runners::Vault

      def log
        @log ||= Class.new { def debug(*); end }.new
      end
    end
    instance = klass.new
    # The runner accesses Legion::Settings[:crypt][:vault][:connected] etc.
    # Build a two-level proxy: crypt_proxy[:vault] returns vault_proxy which
    # reads/writes directly into store (vault_store).
    vault_proxy = Object.new
    vault_proxy.define_singleton_method(:[]) { |k| store[k] }
    vault_proxy.define_singleton_method(:[]=) { |k, v| store[k] = v }
    crypt_proxy = Object.new
    crypt_proxy.define_singleton_method(:[]) { |k| k == :vault ? vault_proxy : store[k] }
    crypt_proxy.define_singleton_method(:[]=) { |k, v| store[k] = v }
    allow(Legion::Settings).to receive(:[]).with(:crypt).and_return(crypt_proxy)
    instance
  end

  describe '#request_token' do
    context 'when vault is already connected' do
      before { vault_store[:connected] = true }

      it 'returns empty hash without publishing' do
        expect(Legion::Extensions::Node::Transport::Messages::RequestVaultToken).not_to receive(:new)
        expect(runner.request_token).to eq({})
      end
    end

    context 'when vault is disabled' do
      before { vault_store[:enabled] = false }

      it 'returns empty hash without publishing' do
        expect(Legion::Extensions::Node::Transport::Messages::RequestVaultToken).not_to receive(:new)
        expect(runner.request_token).to eq({})
      end
    end

    context 'when vault is enabled and not connected' do
      before do
        vault_store[:connected] = false
        vault_store[:enabled] = true
      end

      it 'publishes a RequestVaultToken message' do
        msg = instance_double(Legion::Extensions::Node::Transport::Messages::RequestVaultToken, publish: nil)
        allow(Legion::Extensions::Node::Transport::Messages::RequestVaultToken).to receive(:new).and_return(msg)
        runner.request_token
        expect(Legion::Extensions::Node::Transport::Messages::RequestVaultToken).to have_received(:new)
      end
    end
  end

  describe '#request_vault_token' do
    it 'publishes a RequestVaultToken message and returns empty hash' do
      msg = instance_double(Legion::Extensions::Node::Transport::Messages::RequestVaultToken, publish: nil)
      allow(Legion::Extensions::Node::Transport::Messages::RequestVaultToken).to receive(:new).and_return(msg)
      expect(runner.request_vault_token).to eq({})
    end
  end

  describe '#receive_vault_token' do
    context 'when vault is already connected' do
      before { vault_store[:connected] = true }

      it 'returns already_connected hash without decrypting' do
        expect(Legion::Crypt).not_to receive(:decrypt_from_keypair)
        result = runner.receive_vault_token(message: 'ENC', routing_key: 'rk', public_key: 'PK')
        expect(result[:success]).to be false
        expect(result[:already_connected]).to be true
      end
    end

    context 'when vault is not connected' do
      before do
        vault_store[:connected] = false
        allow(Legion::Crypt).to receive(:decrypt_from_keypair).and_return('DECRYPTED_TOKEN')
        allow(Legion::Crypt).to receive(:connect_vault)
      end

      it 'decrypts and stores the vault token' do
        runner.receive_vault_token(message: 'ENC', routing_key: 'rk', public_key: 'PK')
        expect(vault_store[:token]).to eq('DECRYPTED_TOKEN')
      end

      it 'calls connect_vault after storing token' do
        expect(Legion::Crypt).to receive(:connect_vault)
        runner.receive_vault_token(message: 'ENC', routing_key: 'rk', public_key: 'PK')
      end

      it 'stores provided vault settings when current value is nil' do
        vault_store[:address] = nil
        runner.receive_vault_token(message: 'ENC', routing_key: 'rk', public_key: 'PK', address: 'vault.local')
        expect(vault_store[:address]).to eq('vault.local')
      end

      it 'does not overwrite existing vault settings' do
        vault_store[:address] = 'existing.vault'
        runner.receive_vault_token(message: 'ENC', routing_key: 'rk', public_key: 'PK', address: 'new.vault')
        expect(vault_store[:address]).to eq('existing.vault')
      end

      it 'returns empty hash' do
        expect(runner.receive_vault_token(message: 'ENC', routing_key: 'rk', public_key: 'PK')).to eq({})
      end
    end

    context 'multi-cluster vault' do
      before do
        vault_store[:clusters] = {
          prod: { address: 'vault.example.com', token: nil, connected: false }
        }
        vault_store[:connected] = false
      end

      it 'stores token in cluster entry when cluster_name given' do
        allow(Legion::Crypt).to receive(:connect_vault)
        result = runner.receive_vault_token(token: 'hvs.multi', cluster_name: :prod)
        expect(vault_store[:clusters][:prod][:token]).to eq('hvs.multi')
        expect(result[:success]).to be true
      end
    end

    context 'legacy single-cluster vault' do
      before do
        vault_store[:clusters] = {}
        vault_store[:connected] = false
      end

      it 'stores token in top-level setting when no cluster_name' do
        allow(Legion::Crypt).to receive(:connect_vault)
        runner.receive_vault_token(token: 'hvs.legacy')
        expect(vault_store[:token]).to eq('hvs.legacy')
      end
    end
  end

  describe '#push_vault_token' do
    context 'when no vault token is stored' do
      before { vault_store[:token] = nil }

      it 'returns empty hash without publishing' do
        expect(Legion::Extensions::Node::Transport::Messages::PushVaultToken).not_to receive(:new)
        expect(runner.push_vault_token(public_key: 'PK', node_name: 'other-node')).to eq({})
      end
    end

    context 'when vault token is present' do
      before { vault_store[:token] = 'vault-s.token' }

      it 'encrypts and publishes the token' do
        allow(Legion::Crypt).to receive(:encrypt_from_keypair).and_return('ENCRYPTED_TOKEN')
        msg = instance_double(Legion::Extensions::Node::Transport::Messages::PushVaultToken, publish: nil)
        allow(Legion::Extensions::Node::Transport::Messages::PushVaultToken).to receive(:new).and_return(msg)
        runner.push_vault_token(public_key: 'PK', node_name: 'other-node')
        expect(Legion::Extensions::Node::Transport::Messages::PushVaultToken).to have_received(:new)
      end

      it 'returns empty hash' do
        allow(Legion::Crypt).to receive(:encrypt_from_keypair).and_return('ENCRYPTED_TOKEN')
        msg = instance_double(Legion::Extensions::Node::Transport::Messages::PushVaultToken, publish: nil)
        allow(Legion::Extensions::Node::Transport::Messages::PushVaultToken).to receive(:new).and_return(msg)
        expect(runner.push_vault_token(public_key: 'PK', node_name: 'other-node')).to eq({})
      end
    end
  end
end
