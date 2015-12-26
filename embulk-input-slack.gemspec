
Gem::Specification.new do |spec|
  spec.name          = "embulk-input-slack"
  spec.version       = "0.1.0"
  spec.authors       = ["yoshihara"]
  spec.summary       = "Slack input plugin for Embulk"
  spec.description   = "Loads records from Slack."
  spec.email         = ["h.yoshihara@everyleaf.com"]
  spec.licenses      = ["MIT"]
  # TODO set this: spec.homepage      = "https://github.com/h.yoshihara/embulk-input-slack"

  spec.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  #spec.add_dependency 'YOUR_GEM_DEPENDENCY', ['~> YOUR_GEM_DEPENDENCY_VERSION']
  spec.add_development_dependency 'embulk', ['~> 0.7.5']
  spec.add_development_dependency 'bundler', ['~> 1.0']
  spec.add_development_dependency 'rake', ['>= 10.0']
end
