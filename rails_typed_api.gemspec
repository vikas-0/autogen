# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "rails_typed_api"
  spec.version       = File.read(File.expand_path("lib/rails_typed_api/version.rb", __dir__)).match(/VERSION\s*=\s*\"([^"]+)\"/)[1]
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]

  spec.summary       = "Rails gem to declare/infer request/response types and generate TypeScript + OpenAPI"
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/yourname/rails_typed_api"
  spec.license       = "MIT"

  spec.files         = Dir.glob("{lib}/**/*") + ["README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"

  spec.metadata = {
    "source_code_uri" => spec.homepage
  }
end
