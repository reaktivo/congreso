# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "congreso/version"

Gem::Specification.new do |s|
  s.name        = "congreso"
  s.version     = Congreso::VERSION
  s.authors     = ["Marcel Miranda"]
  s.email       = ["m@reaktivo.com"]
  s.homepage    = "http://reaktivo.com"
  s.summary     = %q{A mexican congress information scraper}
  s.description = %q{A mexican congress information scraper}

  s.rubyforge_project = "congreso"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
