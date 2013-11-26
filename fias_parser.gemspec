# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fias_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "fias_parser"
  spec.version       = FiasParser::VERSION
  spec.authors       = ["Sergey Malykh"]
  spec.email         = ["xronos.i.am@gmail.com"]
  spec.description   = %q{Parse and install FIAS database}
  spec.summary       = %q{Parse and install FIAS database http://fias.nalog.ru/Public/DownloadPage.aspx}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "mechanize"
  spec.add_runtime_dependency "ox"
  spec.add_runtime_dependency "cocaine"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
