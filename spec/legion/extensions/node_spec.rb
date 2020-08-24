require 'spec_helper'

RSpec.describe Legion::Extensions::Node do
  it 'has a version number' do
    expect(Legion::Extensions::Node::VERSION).not_to be nil
  end
end
