# -*- encoding: utf-8 -*-
require File.expand_path("../lib/sinatra/has_scope/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "sinatra-has_scope"
  s.version     = Sinatra::HasScope::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = []
  s.email       = []
  s.homepage    = "http://rubygems.org/gems/sinatra-has_scope"
  s.summary     = "HasScope equivalent for Sinatra"
  s.description = "HasScope readaptation for the Sinatra micro-framework"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "sinatra-has_scope"

  s.add_development_dependency "bundler", ">= 1.0.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
