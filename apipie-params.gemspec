# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "apipie/params/version"

Gem::Specification.new do |s|
  s.name        = "apipie-params"
  s.version     = Apipie::Params::VERSION
  s.authors     = ["Ivan Necas"]
  s.email       = ["inecas@redhat.com"]
  s.homepage    = "http://github.com/iNecas/apipie-params"
  s.summary     = "DSL for describing data structures"
  s.description = "Allows defining structure of data and " +
                  "perform validation against it using json-schema"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency "rake"
  s.add_development_dependency "json-schema"
  s.add_development_dependency "minitest"
end
