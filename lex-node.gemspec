require_relative 'lib/legion/extensions/node/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-node'
  spec.version       = Legion::Extensions::Node::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Does Legion Node things'
  spec.description   = 'This lex is responsible for sending heartbeats, and allowing for dynamic confgs'
  spec.homepage      = 'https://bitbucket.org/legion-io/lex-node/CHANGELOG.md'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://bitbucket.org/legion-io/lex-node'
  spec.metadata['documentation_uri'] = 'https://legionio.atlassian.net/wiki/spaces/LEX/pages/612139025'
  spec.metadata['changelog_uri'] = 'https://legionio.atlassian.net/wiki/spaces/LEX/pages/612139042/'
  spec.metadata['bug_tracker_uri'] = 'https://bitbucket.org/legion-io/lex-node/issues'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'legionio'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov', '< 0.18.0'
end
