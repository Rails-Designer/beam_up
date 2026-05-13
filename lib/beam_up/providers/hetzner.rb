# frozen_string_literal: true

require "beam_up/providers/s3_compatible"

module BeamUp
  module Providers
    class Hetzner < S3Compatible
      class Config
        def self.config_keys = %w[access_key secret_key region bucket]

        attr_accessor :access_key, :secret_key, :region, :bucket

        def with(options)
          self.access_key = options[:access_key]
          self.secret_key = options[:secret_key]
          self.region = options[:region] || "fsn1"
          self.bucket = options[:bucket]
          self
        end

        def validate!
          raise ConfigurationError, "Access key must be set" unless access_key
          raise ConfigurationError, "Secret key must be set" unless secret_key
          raise ConfigurationError, "Bucket must be set" unless bucket
          raise ConfigurationError, "Invalid region: #{region}. Valid regions: fsn1, nbg1, hel1, ash, hil, sin" unless VALID_REGIONS.include?(region)
        end
      end

      private

      VALID_REGIONS = %w[ash fsn1 hel1 hil nbg1 sin]

      def bucket_name = @configuration.bucket

      def endpoint = "https://#{@configuration.region}.your-objectstorage.com"

      def public_url = "https://#{bucket_name}.#{@configuration.region}.your-objectstorage.com"

      def provider_name = "Hetzner"
    end
  end
end
