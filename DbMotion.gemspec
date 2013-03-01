# -*- encoding: utf-8 -*-
require File.expand_path('../lib/DbMotion/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Stephan Toggweiler"]
  gem.email         = ["stephan@rheoli.net"]
  gem.description   = "DbMotion a simple adaption of CoreData."
  gem.summary       = "
                        DbMotion a simple adaption of CoreData.
                      "
  gem.homepage      = "https://github.com/rheoli/DbMotion"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "DbMotion"
  gem.require_paths = ["lib"]
  gem.version       = DbMotion::VERSION
  #gem.add_runtime_dependency("formotion", "~> 1.1.4")
end

