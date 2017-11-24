# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','jtag','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'jtag'
  s.version = Jtag::VERSION
  s.author = 'Brett Terpstra'
  s.email = 'me@brettterpstra.com'
  s.homepage = 'http://brettterpstra.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Auto-tagging and tagging tools for Jekyll'
# Add your other files here if you make them
  s.files = %w(
bin/jtag
lib/jtag/version.rb
lib/jtag/config_files/blacklist.txt
lib/jtag/config_files/config.yml
lib/jtag/config_files/stopwords.txt
lib/jtag/config_files/synonyms.yml
lib/jtag/porter_stemming.rb
lib/jtag/jekylltag.rb
lib/jtag/string.rb
lib/jtag.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = false
  s.extra_rdoc_files = ['README.rdoc','jtag.rdoc']
  s.rdoc_options << '--title' << 'jtag' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'jtag'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','~> 2.17.1')
  s.add_runtime_dependency('json', '~> 1.8.1')
  s.add_runtime_dependency('plist')
end
