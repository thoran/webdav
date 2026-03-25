require_relative './lib/WebDAV/VERSION'

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

  spec.add_dependency('http.rb')

  spec.files = [
    'webdav.gemspec',
    'Gemfile',
    Dir['lib/**/*.rb'],
    'LICENSE',
    'README.md',
    Dir['test/**/*.rb']
  ].flatten

  spec.require_paths = ['lib']
end
