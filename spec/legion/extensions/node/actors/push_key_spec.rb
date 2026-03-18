# frozen_string_literal: true

require 'spec_helper'

unless defined?(Legion::Extensions::Actors::Once)
  module Legion
    module Extensions
      module Actors
        class Once
          def initialize(**); end
        end
      end
    end
  end
end

unless defined?(Legion::Extensions::Node::Runners::Crypt)
  module Legion
    module Extensions
      module Node
        module Runners
          class Crypt
            def self.name
              'Legion::Extensions::Node::Runners::Crypt'
            end
          end
        end
      end
    end
  end
end

require 'legion/extensions/node/actors/push_key'

RSpec.describe Legion::Extensions::Node::Actor::PushKey do
  subject(:instance) { described_class.allocate }

  def call(method_name)
    described_class.instance_method(method_name).bind_call(instance)
  end

  describe '#function' do
    it 'returns "request_public_keys"' do
      expect(call(:function)).to eq('request_public_keys')
    end
  end

  describe '#runner_class' do
    it 'returns Legion::Extensions::Node::Runners::Crypt' do
      expect(call(:runner_class)).to eq(Legion::Extensions::Node::Runners::Crypt)
    end
  end

  describe '#disabled?' do
    it 'returns false' do
      expect(call(:disabled?)).to be false
    end
  end

  describe '#use_runner?' do
    it 'returns true' do
      expect(call(:use_runner?)).to be true
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
end
