# frozen_string_literal: true

require 'legion/extensions/node/version'
require 'legion/extensions/node/helpers/rabbitmq'

module Legion
  module Extensions
    module Node
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
