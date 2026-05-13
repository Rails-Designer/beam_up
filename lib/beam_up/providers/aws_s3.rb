# frozen_string_literal: true

require "beam_up/providers/s3_compatible"

module BeamUp
  module Providers
    class AwsS3 < S3Compatible
      class Config
        def self.config_keys = %w[access_key secret_key region bucket url]

        attr_accessor :access_key, :secret_key, :region, :bucket, :url

        def with(options)
          self.access_key = options[:access_key]
          self.secret_key = options[:secret_key]
          self.region = options[:region] || "us-east-1"
          self.bucket = options[:bucket]
          self.url = options[:url]
          self
        end

        def validate!
          raise ConfigurationError, "Access key must be set" unless access_key
          raise ConfigurationError, "Secret key must be set" unless secret_key
          raise ConfigurationError, "Bucket must be set" unless bucket
        end
      end

      private

      def bucket_name = @configuration.bucket

      def endpoint
        "https://s3.#{@configuration.region}.amazonaws.com"
      end

      def public_url
        @configuration.url || "https://#{bucket_name}.s3.#{@configuration.region}.amazonaws.com"
      end

      def provider_name = "AWS S3"
    end
  end
end
