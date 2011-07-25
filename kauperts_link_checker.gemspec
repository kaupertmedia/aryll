$:.push File.expand_path("../lib/", __FILE__)

Gem::Specification.new do |s|
  s.name = "kauperts_link_checker"
  s.version = "0.0.3"
  s.platform = Gem::Platform::RUBY
  s.authors = ["Wolfgang Vogl", "Carsten Zimmermann"]
  s.email = ["w.vogl@kaupertmedia.de"]
  s.homepage = ""

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency "simpleidn"

  s.add_development_dependency 'mocha'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'redgreen'
  s.add_development_dependency 'activesupport'
end
