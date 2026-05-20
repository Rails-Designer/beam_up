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

    def config_file=(path)
      Core.config_file = path
    end

    def configuration(config_file: nil) = Core.configuration(config_file: config_file)

    def deploy!(path = nil, provider: nil, to: nil, config_file: nil) = Core.deploy!(path, provider: (to || provider)&.to_s, config_file: config_file)
  end
end
