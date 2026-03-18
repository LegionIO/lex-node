# frozen_string_literal: true

require 'spec_helper'

unless defined?(Legion::Extensions::Actors::Every)
  module Legion
    module Extensions
      module Actors
        class Every
          def settings
            Legion::Settings
          end
        end
      end
    end
  end
end

unless defined?(Legion::Settings)
  module Legion
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
end

require 'legion/extensions/node/actors/beat'

RSpec.describe Legion::Extensions::Node::Actor::Beat do
  subject(:instance) { described_class.allocate }

  def call(method_name)
    described_class.instance_method(method_name).bind_call(instance)
  end

  describe '#runner_function' do
    it 'returns "beat"' do
      expect(call(:runner_function)).to eq('beat')
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(call(:use_runner?)).to be false
    end
  end

  describe '#check_subtask?' do
    it 'returns false' do
      expect(call(:check_subtask?)).to be false
    end
  end

  describe '#generate_task?' do
    it 'returns false' do
      expect(call(:generate_task?)).to be false
    end
  end

  describe '#run_now?' do
    it 'returns true' do
      expect(call(:run_now?)).to be true
    end
  end

  describe '#time' do
    it 'reads beat_interval from settings' do
      allow(Legion::Settings).to receive(:[]).with(:beat_interval).and_return(30)
      expect(call(:time)).to eq(30)
    end

    it 'returns nil when beat_interval is not configured' do
      allow(Legion::Settings).to receive(:[]).with(:beat_interval).and_return(nil)
      expect(call(:time)).to be_nil
    end
  end
end
