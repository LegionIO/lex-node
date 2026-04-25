# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/node/control_auth'

RSpec.describe Legion::Extensions::Node::ControlAuth do
  before do
    allow(Legion::Settings).to receive(:dig).with(:cluster, :control_secret).and_return('shared-secret')
    allow(Legion::Settings).to receive(:dig).with(:crypt, :cluster_secret).and_return(nil)
    allow(Legion::Settings).to receive(:[]).with(:client).and_return({ name: 'sender-node' })
  end

  it 'signs and verifies cluster control payloads' do
    payload = described_class.sign(function: 'update_settings', settings: { extensions: { blocked: ['bad'] } })

    expect(payload[:control]).to include(:sender, :timestamp, :nonce, :signature)
    expect(described_class.verify!(payload)).to eq(payload)
  end

  it 'rejects unsigned payloads' do
    expect { described_class.verify!(function: 'update_settings') }
      .to raise_error(Legion::Extensions::Node::ControlAuth::UnauthorizedControlMessage)
  end

  it 'rejects malformed payloads predictably' do
    expect { described_class.verify!(nil) }
      .to raise_error(Legion::Extensions::Node::ControlAuth::UnauthorizedControlMessage, 'missing control signature')
  end

  it 'rejects payloads without a valid nonce' do
    payload = described_class.sign(function: 'update_settings', settings: { feature: true })
    payload[:control] = payload[:control].merge(nonce: '')

    expect { described_class.verify!(payload) }
      .to raise_error(Legion::Extensions::Node::ControlAuth::UnauthorizedControlMessage, 'invalid control nonce')
  end

  it 'rejects tampered payloads' do
    payload = described_class.sign(function: 'update_settings', settings: { feature: true })
    payload[:settings] = { feature: false }

    expect { described_class.verify!(payload) }
      .to raise_error(Legion::Extensions::Node::ControlAuth::UnauthorizedControlMessage)
  end
end
