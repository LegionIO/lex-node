# frozen_string_literal: true

require 'spec_helper'

unless defined?(Legion::Extensions::Actors::Subscription)
  module Legion
    module Extensions
      module Actors
        class Subscription
          def initialize(**); end
        end
      end
    end
  end
end

unless defined?(Legion::Extensions::Node::Runners::Node)
  module Legion
    module Extensions
      module Node
        module Runners
          module Node
          end
        end
      end
    end
  end
end

unless defined?(Legion::Extensions::Node::Transport::Queues::ClusterControl)
  module Legion
    module Extensions
      module Node
        module Transport
          module Queues
            ClusterControl = Class.new
          end
        end
      end
    end
  end
end

require 'legion/extensions/node/actors/cluster_control'

RSpec.describe Legion::Extensions::Node::Actor::ClusterControl do
  subject(:instance) { described_class.allocate }

  def call(method_name)
    described_class.instance_method(method_name).bind_call(instance)
  end

  describe '#runner_class' do
    it 'returns Legion::Extensions::Node::Runners::Node' do
      expect(call(:runner_class)).to eq(Legion::Extensions::Node::Runners::Node)
    end
  end

  describe '#queue_class' do
    it 'returns Legion::Extensions::Node::Transport::Queues::ClusterControl' do
      expect(call(:queue_class)).to eq(Legion::Extensions::Node::Transport::Queues::ClusterControl)
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
