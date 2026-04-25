# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/node/control_auth'

RSpec.describe Legion::Extensions::Node::ControlAuth do
  before do
    allow(Legion::Settings).to receive(:dig).and_return(nil)
    allow(Legion::Settings).to receive(:dig).with(:extensions, :node).and_return({})
    allow(Legion::Settings).to receive(:dig).with(:cluster, :control_secret).and_return('shared-secret')
    allow(Legion::Settings).to receive(:[]).with(:client).and_return({ name: 'sender-node' })
  end

  it 'signs and verifies cluster control payloads when a shared secret is configured' do
    payload = described_class.sign(function: 'update_settings', settings: { extensions: { blocked: ['bad'] } })

    expect(payload[:control]).to include(:sender, :timestamp, :nonce, :signature)
    expect(described_class.verify!(payload)).to eq(payload)
  end

  it 'passes unsigned payloads in auto mode when no shared secret is configured' do
    allow(Legion::Settings).to receive(:dig).with(:cluster, :control_secret).and_return(nil)

    payload = described_class.sign(function: 'update_settings')

    expect(payload).not_to include(:control)
    expect(described_class.verify!(payload)).to eq(payload)
  end

  it 'rejects unsigned payloads when a shared secret is configured' do
    expect { described_class.verify!(function: 'update_settings') }
      .to raise_error(Legion::Extensions::Node::ControlAuth::UnauthorizedControlMessage)
  end

  it 'requires signed payloads when auth mode is required' do
    allow(Legion::Settings).to receive(:dig).with(:extensions, :node).and_return(
      cluster_control: { auth: { mode: 'required' } }
    )
    allow(Legion::Settings).to receive(:dig).with(:cluster, :control_secret).and_return(nil)

    expect { described_class.verify!(function: 'update_settings') }
      .to raise_error(Legion::Extensions::Node::ControlAuth::UnauthorizedControlMessage)
  end

  it 'does not sign or verify payloads when auth mode is disabled' do
    allow(Legion::Settings).to receive(:dig).with(:extensions, :node).and_return(
      cluster_control: { auth: { mode: 'disabled' } }
    )

    payload = described_class.sign(function: 'update_settings', settings: { feature: true })
    tampered = payload.merge(settings: { feature: false })

    expect(payload).not_to include(:control)
    expect(described_class.verify!(tampered)).to eq(tampered)
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

  it 'uses configured nonce byte length' do
    allow(Legion::Settings).to receive(:dig).with(:extensions, :node).and_return(
      cluster_control: { auth: { nonce_bytes: 8 } }
    )

    payload = described_class.sign(function: 'update_settings', settings: { feature: true })

    expect(payload[:control][:nonce]).to match(/\A[0-9a-f]{16}\z/i)
    expect(described_class.verify!(payload)).to eq(payload)
  end

  it 'uses configured timestamp skew' do
    allow(Legion::Settings).to receive(:dig).with(:extensions, :node).and_return(
      cluster_control: { auth: { timestamp_skew_seconds: 1 } }
    )
    allow(Time).to receive(:now).and_return(Time.utc(2026, 1, 1, 0, 0, 0))
    payload = described_class.sign(function: 'update_settings', settings: { feature: true })
    allow(Time).to receive(:now).and_return(Time.utc(2026, 1, 1, 0, 0, 2))

    expect { described_class.verify!(payload) }
      .to raise_error(Legion::Extensions::Node::ControlAuth::UnauthorizedControlMessage, 'stale control message')
  end

  it 'rejects tampered payloads' do
    payload = described_class.sign(function: 'update_settings', settings: { feature: true })
    payload[:settings] = { feature: false }

    expect { described_class.verify!(payload) }
      .to raise_error(Legion::Extensions::Node::ControlAuth::UnauthorizedControlMessage)
  end
end
