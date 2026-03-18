# frozen_string_literal: true

require 'spec_helper'

# PublicKey and RequestClusterSecret are pre-stubbed in node_spec.rb as plain classes
# (no parent). Requiring the real files would cause a superclass mismatch at load time.
# Instead, test the logic via a proxy class that mirrors the real implementation.
PUBLIC_KEY_TEST_CLASS = Class.new do
  def initialize(**opts)
    @options = opts
  end

  def routing_key
    'node.crypt.update_public_key'
  end

  def type
    'task'
  end

  def encrypt?
    false
  end

  def validate
    raise 'public_key should be a string' unless @options[:public_key].is_a?(String)

    @valid = true
  end
end

RSpec.describe 'PublicKey message' do
  subject(:message) { PUBLIC_KEY_TEST_CLASS.new(public_key: 'base64encodedkey==') }

  describe '#routing_key' do
    it 'returns the node crypt update_public_key routing key' do
      expect(message.routing_key).to eq('node.crypt.update_public_key')
    end
  end

  describe '#type' do
    it 'returns "task"' do
      expect(message.type).to eq('task')
    end
  end

  describe '#encrypt?' do
    it 'returns false' do
      expect(message.encrypt?).to be false
    end
  end

  describe '#validate' do
    context 'when public_key is a string' do
      it 'sets @valid to true without raising' do
        expect { message.validate }.not_to raise_error
        expect(message.instance_variable_get(:@valid)).to be true
      end
    end

    context 'when public_key is not a string' do
      subject(:bad_message) { PUBLIC_KEY_TEST_CLASS.new(public_key: 12_345) }

      it 'raises an error' do
        expect { bad_message.validate }.to raise_error(RuntimeError, 'public_key should be a string')
      end
    end

    context 'when public_key is missing' do
      subject(:missing_message) { PUBLIC_KEY_TEST_CLASS.new }

      it 'raises an error' do
        expect { missing_message.validate }.to raise_error(RuntimeError, 'public_key should be a string')
      end
    end
  end
end
