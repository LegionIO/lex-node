# frozen_string_literal: true

require 'spec_helper'

# Stub framework dependencies before loading the runner
module Legion
  VERSION = '0.1.0' unless defined?(Legion::VERSION)

  module Extensions
    module Helpers
      module Transport
        def messages; Messages end
        module Messages
          class Beat
            def initialize(**); end
            def publish; end
          end
        end
      end
      module Lex; end
    end

    module Node
      module Transport
        module Messages
          class Beat
            def initialize(**); end
            def publish; end
          end
        end
      end
    end
  end

  module Logging
    def self.debug(*); end
  end
end unless defined?(Legion::Extensions::Helpers::Transport)

require 'legion/extensions/node/runners/beat'

RSpec.describe Legion::Extensions::Node::Runners::Beat do
  let(:runner) do
    klass = Class.new do
      include Legion::Extensions::Node::Runners::Beat

      def log
        @log ||= Class.new do
          def debug(*); end
        end.new
      end

      def messages
        Legion::Extensions::Node::Transport::Messages
      end
    end
    klass.new
  end

  describe '#beat' do
    it 'returns success: true' do
      allow_any_instance_of(Legion::Extensions::Node::Transport::Messages::Beat).to receive(:publish)
      result = runner.beat
      expect(result[:success]).to eq(true)
    end

    it 'defaults status to active' do
      allow_any_instance_of(Legion::Extensions::Node::Transport::Messages::Beat).to receive(:publish)
      result = runner.beat
      expect(result[:status]).to eq('active')
    end

    it 'uses provided status' do
      allow_any_instance_of(Legion::Extensions::Node::Transport::Messages::Beat).to receive(:publish)
      result = runner.beat(status: 'draining')
      expect(result[:status]).to eq('draining')
    end

    it 'includes Legion::VERSION in the result' do
      allow_any_instance_of(Legion::Extensions::Node::Transport::Messages::Beat).to receive(:publish)
      result = runner.beat
      expect(result).to have_key(:version)
    end

    it 'passes extra opts through to result' do
      allow_any_instance_of(Legion::Extensions::Node::Transport::Messages::Beat).to receive(:publish)
      result = runner.beat(node_id: 7)
      expect(result[:node_id]).to eq(7)
    end

    it 'publishes a Beat message' do
      msg = instance_double(Legion::Extensions::Node::Transport::Messages::Beat)
      expect(msg).to receive(:publish)
      allow(Legion::Extensions::Node::Transport::Messages::Beat).to receive(:new).and_return(msg)
      runner.beat
    end

    it 'publishes with the given status' do
      msg = instance_double(Legion::Extensions::Node::Transport::Messages::Beat)
      allow(msg).to receive(:publish)
      allow(Legion::Extensions::Node::Transport::Messages::Beat).to receive(:new).with(status: 'draining').and_return(msg)
      runner.beat(status: 'draining')
    end
  end
end
