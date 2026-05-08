require_relative './lib/WebDAV/VERSION'

class Gem::Specification
  def dependencies=(gems)
    gems.each{|gem| add_dependency(*gem)}
  end

  def development_dependencies=(gems)
    gems.each{|gem| add_development_dependency(*gem)}
  end
end

Gem::Specification.new do |spec|
  spec.name = 'webdav'
  spec.version = WebDAV::VERSION

  spec.summary = "A Ruby WebDAV client library."
  spec.description = "A Ruby WebDAV client library."

  spec.author = 'thoran'
  spec.email = 'code@thoran.com'
  spec.homepage = 'https://github.com/thoran/webdav'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 2.7'
  spec.require_paths = ['lib']

  spec.files = [
    'webdav.gemspec',
    'CHANGELOG',
    'Gemfile',
    'LICENSE',
    'Rakefile',
    'README.md',
    Dir['lib/**/*.rb'],
    Dir['test/**/*.rb']
  ].flatten

  spec.dependencies = [
    ['http.rb', '>= 0.18.0']
  ]

  spec.development_dependencies = %w{
    minitest
    rake
  }
end
