require_relative 'lib/legion/extensions/node/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-node'
  spec.version       = Legion::Extensions::Node::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Does Legion Node things'
  spec.description   = 'This lex is responsible for sending heartbeats, allowing for dynamic config, cluster secret, etc'
  spec.homepage      = 'https://github.com/LegionIO/lex-node'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/LegionIO/lex-node'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-node'
  spec.metadata['changelog_uri'] = 'https://github.com/LegionIO/lex-node'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/LegionIO/lex-node/issues'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
end
