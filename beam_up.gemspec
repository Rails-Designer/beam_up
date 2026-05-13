# frozen_string_literal: true

require_relative "lib/beam_up/version"

Gem::Specification.new do |spec|
  spec.name = "beam_up"
  spec.version = BeamUp::VERSION
  spec.authors = ["Rails Designer"]
  spec.email = ["developers@railsdesigner.com"]

  spec.summary = "A CLI tool that deploys your static sites to multiple hosting providers from a single command."
  spec.description = "Beam Up is a deployment CLI for static sites that works with popular hosting providers like Netlify, AWS S3, Bunny, DigitalOcean Spaces and Hetzner. Configure it once, then deploy your site to any provider with a single command. Use it from the command line, embed it in your Ruby scripts or integrate it into your CI/CD pipeline."
  spec.homepage = "https://railsdesigner.com/open-source/beam-up/"
  spec.license = "MIT"

  spec.files = Dir["lib/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { File.basename(it) }

  spec.add_dependency "aws-sdk-s3", "~> 1.0"
  spec.add_dependency "rexml", "~> 3.0"
  spec.add_dependency "rubyzip", "~> 3.0"
end
