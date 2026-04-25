# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/node/config'

RSpec.describe Legion::Extensions::Node::Config do
  before do
    allow(Legion::Settings).to receive(:dig).and_return(nil)
  end

  describe '.default_settings' do
    it 'returns a defensive copy of the node defaults' do
      settings = described_class.default_settings
      settings[:cluster_control][:auth][:mode] = 'disabled'

      expect(described_class.default_settings[:cluster_control][:auth][:mode]).to eq('auto')
    end
  end

  describe '.control_auth' do
    it 'deep merges string-keyed settings over defaults' do
      allow(Legion::Settings).to receive(:dig).with(:extensions, :node).and_return(
        'cluster_control' => {
          'auth' => {
            'mode'                   => 'required',
            'timestamp_skew_seconds' => 60
          }
        }
      )

      expect(described_class.control_auth).to include(
        mode:                   'required',
        timestamp_skew_seconds: 60,
        nonce_bytes:            16
      )
    end
  end

  describe '.control_queue' do
    it 'deep merges partial queue overrides over defaults' do
      allow(Legion::Settings).to receive(:dig).with(:extensions, :node).and_return(
        cluster_control: {
          queue: {
            durable:    false,
            expires_ms: nil
          }
        }
      )

      expect(described_class.control_queue).to include(
        durable:        false,
        exclusive:      false,
        auto_delete:    false,
        queue_type:     'classic',
        expires_ms:     nil,
        message_ttl_ms: 86_400_000,
        max_length:     1000
      )
    end
  end
end
