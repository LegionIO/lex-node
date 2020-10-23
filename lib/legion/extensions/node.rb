require 'legion/extensions/node/version'

module Legion
  module Extensions
    module Node
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
