module Legion::Extensions::Node::Runners
  module Node
    def self.message(_options = {}, **hash)
      hash.each do |k, v|
        raise 'Cannot override base setting that doesn\'t exist' if Legion::Settings[k].nil?

        if v.is_a? String
          Legion::Settings[k] = v
        elsif v.is_a? Hash
          v.each do |key, value|
            Legion::Settings[k][key] = value
          end
        end
      end
    end
  end
end
