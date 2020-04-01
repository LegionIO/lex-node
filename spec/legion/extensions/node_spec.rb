require 'spec_helper'

require 'legion/extensions/node/runners/beat'
require 'legion/extensions/node/runners/crypt'
require 'legion/extensions/node/runners/node'

RSpec.describe Legion::Extensions::Node do
  it 'has a version number' do
    expect(Legion::Extensions::Node::VERSION).not_to be nil
  end

  it { should be_a Legion::Extensions::Core }
  it { should respond_to :autobuild }
end
