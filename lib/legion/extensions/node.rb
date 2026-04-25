# frozen_string_literal: true

require 'legion/extensions/node/version'
require 'legion/extensions/node/config'
require 'legion/extensions/node/helpers/rabbitmq'

module Legion
  module Extensions
    module Node
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false

      def self.default_settings
        Config.default_settings
      end
    end
  end
end
