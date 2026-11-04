# Ensure we require the local version and not one we might have installed already
require "./lib/jtag/version.rb"
spec = Gem::Specification.new do |s|
  s.name = "jtag"
  s.version = Jtag::VERSION
  s.author = "Brett Terpstra"
  s.email = "me@brettterpstra.com"
  s.homepage = "http://brettterpstra.com"
  s.license = nil
  s.required_ruby_version = ">= 3.3"
  s.platform = Gem::Platform::RUBY
  s.summary = "Auto-tagging and tagging tools for Jekyll"
  # Add your other files here if you make them
  s.files = `git ls-files -z`.split("\x0").reject { |f| f.strip =~ %r{^((test|spec|features)/|\.git|buildnotes|.*\.taskpaper)} }

  s.require_paths << "lib"
  s.extra_rdoc_files = ["README.rdoc", "jtag.rdoc"]
  s.rdoc_options << "--title" << "jtag" << "--main" << "README.rdoc"
  s.bindir = "bin"
  s.executables << "jtag"
  s.add_development_dependency("rake", "~> 13.0")
  s.add_development_dependency("rdoc", "~> 6.6")
  s.add_development_dependency("aruba", "~> 2.0")
  s.add_runtime_dependency("gli", "= 2.20.0")
  s.add_runtime_dependency("plist", "~> 3.7")
  s.add_runtime_dependency("csv", "~> 3.2")
end
