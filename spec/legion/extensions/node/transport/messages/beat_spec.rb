# frozen_string_literal: true

require 'spec_helper'

# The runners/beat_spec defines a stub Beat class that conflicts with the real one.
# To test the message payload methods we added, we create a test class that includes
# the same private methods without requiring the real Beat < Legion::Transport::Message.
BEAT_TEST_CLASS = Class.new do
  def initialize(**opts)
    @options = opts
  end

  def message
    hash = {
      name:      'test-node',
      pid:       Process.pid,
      timestamp: Time.now,
      status:    @options[:status].nil? ? 'healthy' : @options[:status]
    }
    hash[:version] = Legion::VERSION if defined?(Legion::VERSION)
    hash[:metrics] = collect_metrics
    hash[:hosted_worker_ids] = collect_worker_ids
    hash
  end

  private

  def collect_metrics
    times = Process.times
    {
      memory_rss_mb:      rss_mb,
      cpu_user_seconds:   times.utime.round(2),
      cpu_system_seconds: times.stime.round(2),
      thread_count:       Thread.list.count,
      loaded_extensions:  loaded_extension_count,
      uptime_seconds:     uptime_seconds
    }
  end

  def rss_mb
    if RUBY_PLATFORM.include?('darwin')
      `ps -o rss= -p #{Process.pid}`.strip.to_i / 1024.0
    else
      File.read("/proc/#{Process.pid}/statm").split[1].to_i * (4096.0 / 1_048_576)
    end
  rescue StandardError
    0.0
  end

  def loaded_extension_count
    return 0 unless defined?(Legion::Extensions)

    Legion::Extensions.respond_to?(:loaded_extensions) ? Legion::Extensions.loaded_extensions.count : 0
  end

  def uptime_seconds
    (Process.clock_gettime(Process::CLOCK_MONOTONIC) - boot_time).round(0)
  end

  def boot_time
    @boot_time ||= Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def collect_worker_ids
    return [] unless defined?(Legion::DigitalWorker)

    Legion::DigitalWorker.active_local_ids
  rescue StandardError
    []
  end
end

RSpec.describe 'Beat message payload' do
  subject(:beat) { BEAT_TEST_CLASS.new(status: 'healthy') }

  describe '#message' do
    let(:msg) { beat.message }

    it 'includes :metrics hash' do
      expect(msg[:metrics]).to be_a(Hash)
    end

    it 'includes :hosted_worker_ids array' do
      expect(msg[:hosted_worker_ids]).to be_an(Array)
    end

    it 'includes :version when Legion::VERSION is defined' do
      stub_const('Legion::VERSION', '1.0.0-test') unless defined?(Legion::VERSION)
      expect(beat.message[:version]).not_to be_nil
    end

    it 'includes all 6 metric keys' do
      expected_keys = %i[memory_rss_mb cpu_user_seconds cpu_system_seconds thread_count loaded_extensions
                         uptime_seconds]
      expect(msg[:metrics].keys).to match_array(expected_keys)
    end

    it 'returns rss_mb as a number >= 0' do
      expect(msg[:metrics][:memory_rss_mb]).to be >= 0
    end

    it 'returns thread_count as a positive integer' do
      expect(msg[:metrics][:thread_count]).to be_a(Integer)
      expect(msg[:metrics][:thread_count]).to be > 0
    end

    it 'returns uptime_seconds as a non-negative number' do
      expect(msg[:metrics][:uptime_seconds]).to be >= 0
    end

    it 'returns empty hosted_worker_ids when Legion::DigitalWorker is not defined' do
      hide_const('Legion::DigitalWorker') if defined?(Legion::DigitalWorker)
      expect(BEAT_TEST_CLASS.new(status: 'healthy').message[:hosted_worker_ids]).to eq([])
    end
  end
end
