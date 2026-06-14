# frozen_string_literal: true

require "beam_up/providers/s3_compatible"

module BeamUp
  module Providers
    class DigitalOceanSpaces < S3Compatible
      def self.display_name = "DigitalOcean Spaces"

      class Config
        def self.config_keys = %w[access_key secret_key region space_name]

        attr_accessor :access_key, :secret_key, :region, :space_name

        def with(options)
          self.access_key = options[:access_key]
          self.secret_key = options[:secret_key]
          self.region = options[:region]
          self.space_name = options[:space_name]
          self
        end

        def validate!
          raise ConfigurationError, "Access key must be set" unless access_key
          raise ConfigurationError, "Secret key must be set" unless secret_key
        end
      end

      private

      def bucket_name
        return @configuration.space_name if @configuration.space_name
        return @created_bucket_name if @created_bucket_name

        name = "#{File.basename(Dir.pwd)}-#{SecureRandom.hex(4)}"
        s3_client.create_bucket(bucket: name)

        @created_bucket_name = name
      end

      def endpoint = "https://#{@configuration.region}.digitaloceanspaces.com"

      def public_url = "https://#{bucket_name}.#{@configuration.region}.cdn.digitaloceanspaces.com"

      def provider_name = "DigitalOcean Spaces"
    end
  end
end
