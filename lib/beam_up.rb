# frozen_string_literal: true

require "beam_up/version"
require "beam_up/errors"
require "beam_up/providers"
require "beam_up/configuration"
require "beam_up/result"
require "beam_up/core"
require "beam_up/cli"

module BeamUp
  PROVIDERS = {
    "aws_s3" => Providers::AwsS3,
    "bunny" => Providers::Bunny,
    "digital_ocean_spaces" => Providers::DigitalOceanSpaces,
    "hetzner" => Providers::Hetzner,
    "neocities" => Providers::Neocities,
    "netlify" => Providers::Netlify,
    "sftp" => Providers::SFTP,
    "statichost" => Providers::Statichost,
    "transporter" => Providers::Transporter
  }

  class << self
    def configure(&block) = Core.configure(&block)

    def configuration = Core.configuration

    def deploy!(path = nil, provider: nil, to: nil) = Core.deploy!(path, provider: (to || provider)&.to_s)
  end
end
