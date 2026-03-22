# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/node/helpers/rabbitmq'

RSpec.describe Legion::Extensions::Node::Helpers::Rabbitmq do
  let(:settings) do
    {
      connection:      { host: '127.0.0.1', user: 'guest', password: 'guest', vhost: '/' },
      management_port: 15_672
    }
  end

  let(:http_instance) { instance_double(Net::HTTP) }

  let(:nodes_body) do
    [
      { 'name' => 'rabbit@node1', 'running' => true },
      { 'name' => 'rabbit@node2', 'running' => true },
      { 'name' => 'rabbit@node3', 'running' => true }
    ]
  end

  let(:nodes_partial_body) do
    [
      { 'name' => 'rabbit@node1', 'running' => true },
      { 'name' => 'rabbit@node2', 'running' => false }
    ]
  end

  let(:queues_body) do
    [
      { 'name' => 'legion.tasks', 'type' => 'quorum', 'leader' => 'rabbit@node1' },
      { 'name' => 'legion.events', 'type' => 'quorum', 'leader' => 'rabbit@node2' },
      { 'name' => 'legion.logs', 'type' => 'classic', 'leader' => nil }
    ]
  end

  let(:shovels_body) do
    [
      { 'name' => 'shovel1', 'state' => 'running' },
      { 'name' => 'shovel2', 'state' => 'running' }
    ]
  end

  let(:whoami_body) { { 'name' => 'guest', 'tags' => ['administrator'] } }

  let(:ok_response) do
    instance_double(Net::HTTPResponse, code: '200', body: '[]')
  end

  before do
    allow(Net::HTTP).to receive(:new).and_return(http_instance)
    allow(http_instance).to receive(:open_timeout=)
    allow(http_instance).to receive(:read_timeout=)
  end

  describe '.cluster_health' do
    before do
      allow(http_instance).to receive(:request) do |req|
        body = case req.path
               when '/api/nodes' then nodes_body
               when %r{^/api/queues/} then queues_body
               when %r{^/api/shovels/} then shovels_body
               when '/api/whoami' then whoami_body
               else []
               end
        instance_double(Net::HTTPResponse, code: '200', body: JSON.dump(body))
      end
    end

    it 'returns a hash with node_count, quorum_leaders, and shovel_links keys' do
      result = described_class.cluster_health(settings: settings)
      expect(result).to have_key(:node_count)
      expect(result).to have_key(:quorum_leaders)
      expect(result).to have_key(:shovel_links)
    end

    it 'returns all unknown statuses when API is unreachable' do
      allow(http_instance).to receive(:request).and_raise(Errno::ECONNREFUSED)
      result = described_class.cluster_health(settings: settings)
      expect(result[:node_count][:status]).to eq('unknown')
      expect(result[:quorum_leaders][:status]).to eq('unknown')
      expect(result[:shovel_links][:status]).to eq('unknown')
    end
  end

  describe '.fetch_node_count' do
    it 'returns ok when all nodes are running' do
      response = instance_double(Net::HTTPResponse, code: '200', body: JSON.dump(nodes_body))
      allow(http_instance).to receive(:request).and_return(response)

      result = described_class.fetch_node_count(http_instance, settings)
      expect(result[:status]).to eq('ok')
      expect(result[:running]).to eq(3)
      expect(result[:total]).to eq(3)
    end

    it 'returns warn when some nodes are down' do
      response = instance_double(Net::HTTPResponse, code: '200', body: JSON.dump(nodes_partial_body))
      allow(http_instance).to receive(:request).and_return(response)

      result = described_class.fetch_node_count(http_instance, settings)
      expect(result[:status]).to eq('warn')
      expect(result[:running]).to eq(1)
      expect(result[:total]).to eq(2)
    end

    it 'returns critical when no nodes are running' do
      all_down = [{ 'name' => 'rabbit@node1', 'running' => false }]
      response = instance_double(Net::HTTPResponse, code: '200', body: JSON.dump(all_down))
      allow(http_instance).to receive(:request).and_return(response)

      result = described_class.fetch_node_count(http_instance, settings)
      expect(result[:status]).to eq('critical')
    end

    it 'returns unreachable when API returns non-2xx' do
      response = instance_double(Net::HTTPResponse, code: '500', body: 'error')
      allow(http_instance).to receive(:request).and_return(response)

      result = described_class.fetch_node_count(http_instance, settings)
      expect(result[:status]).to eq('unknown')
    end
  end

  describe '.fetch_quorum_leaders' do
    before do
      allow(http_instance).to receive(:request) do |req|
        body = case req.path
               when %r{^/api/queues/} then queues_body
               when '/api/nodes' then nodes_body
               when '/api/whoami' then whoami_body
               else []
               end
        instance_double(Net::HTTPResponse, code: '200', body: JSON.dump(body))
      end
    end

    it 'counts quorum queues and leaders' do
      result = described_class.fetch_quorum_leaders(http_instance, settings)
      expect(result[:status]).to eq('ok')
      expect(result[:quorum_queues]).to eq(2)
    end

    it 'returns zero counts when no quorum queues exist' do
      classic_only = [{ 'name' => 'q1', 'type' => 'classic', 'leader' => nil }]
      allow(http_instance).to receive(:request) do |req|
        body = req.path.start_with?('/api/queues') ? classic_only : nodes_body
        instance_double(Net::HTTPResponse, code: '200', body: JSON.dump(body))
      end

      result = described_class.fetch_quorum_leaders(http_instance, settings)
      expect(result[:quorum_queues]).to eq(0)
      expect(result[:leaders_on_this_node]).to eq(0)
    end

    it 'encodes vhost in the URL path' do
      custom = settings.dup
      custom[:connection] = custom[:connection].merge(vhost: '/my-vhost')

      expect(http_instance).to receive(:request) do |req|
        expect(req.path).to include('%2Fmy-vhost') if req.path.include?('queues')
        instance_double(Net::HTTPResponse, code: '200', body: JSON.dump(queues_body))
      end.at_least(:once)

      described_class.fetch_quorum_leaders(http_instance, custom)
    end
  end

  describe '.fetch_shovel_links' do
    it 'returns ok with running counts when shovels are healthy' do
      response = instance_double(Net::HTTPResponse, code: '200', body: JSON.dump(shovels_body))
      allow(http_instance).to receive(:request).and_return(response)

      result = described_class.fetch_shovel_links(http_instance, settings)
      expect(result[:status]).to eq('ok')
      expect(result[:total]).to eq(2)
      expect(result[:running]).to eq(2)
    end

    it 'returns warn when some shovels are not running' do
      degraded = [
        { 'name' => 'shovel1', 'state' => 'running' },
        { 'name' => 'shovel2', 'state' => 'terminated' }
      ]
      response = instance_double(Net::HTTPResponse, code: '200', body: JSON.dump(degraded))
      allow(http_instance).to receive(:request).and_return(response)

      result = described_class.fetch_shovel_links(http_instance, settings)
      expect(result[:status]).to eq('warn')
      expect(result[:running]).to eq(1)
    end

    it 'returns ok with zero counts when no shovels configured' do
      response = instance_double(Net::HTTPResponse, code: '200', body: JSON.dump([]))
      allow(http_instance).to receive(:request).and_return(response)

      result = described_class.fetch_shovel_links(http_instance, settings)
      expect(result[:status]).to eq('ok')
      expect(result[:total]).to eq(0)
    end

    it 'returns unknown when shovels API returns 404' do
      response = instance_double(Net::HTTPResponse, code: '404', body: 'not found')
      allow(http_instance).to receive(:request).and_return(response)

      result = described_class.fetch_shovel_links(http_instance, settings)
      expect(result[:status]).to eq('unknown')
    end
  end

  describe '.build_http' do
    it 'uses host and management_port from settings' do
      expect(Net::HTTP).to receive(:new).with('10.0.0.1', 25_672).and_return(http_instance)
      described_class.build_http(connection: { host: '10.0.0.1' }, management_port: 25_672)
    end

    it 'defaults to 127.0.0.1:15672 when settings are missing' do
      expect(Net::HTTP).to receive(:new).with('127.0.0.1', 15_672).and_return(http_instance)
      described_class.build_http(connection: {}, management_port: nil)
    end
  end
end
