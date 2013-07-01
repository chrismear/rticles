$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rticles/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rticles"
  s.version     = Rticles::VERSION
  s.authors     = ["Chris Mear"]
  s.email       = ["getinvolved@oneclickorgs.com"]
  s.homepage    = "https://github.com/oneclickorgs/rticles"
  s.summary     = "Consistent editing for legal documents."
  s.description = "Rticles is a Rails plugin that allows for web-based editing of legal documents. It lets you create nested, numbered paragraphs, along with intra-document references that remain accurate as paragraphs are inserted, removed and moved."
  s.licenses    = ['AGPL-3']

  s.files       = `git ls-files`.split($\)

  s.add_dependency "rails", "~> 3.2.8"
  s.add_dependency "acts_as_list", "~>0.1.8"
  s.add_dependency "roman-numerals", "~>0.3.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "equivalent-xml"
  s.add_development_dependency "coveralls"
end
