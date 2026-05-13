# frozen_string_literal: true

require "net/http"
require "digest"

module BeamUp
  module Providers
    class Bunny < Base
      class Config
        def self.config_keys = %w[storage_zone_password storage_zone_name region]

        attr_accessor :storage_zone_password, :storage_zone_name, :region

        def with(options)
          self.storage_zone_password = options[:storage_zone_password]
          self.storage_zone_name = options[:storage_zone_name]
          self.region = options[:region] || "de"
          self
        end

        def validate!
          raise ConfigurationError, "Storage zone password must be set" unless storage_zone_password
          raise ConfigurationError, "Storage zone name must be set" unless storage_zone_name
        end
      end

      def deploy!(path)
        @path = path

        files_to_deploy.each do |file|
          upload file
        end

        Result.new(
          provider: "Bunny",
          deploy_id: Time.now.to_i.to_s,
          url: "https://#{@configuration.storage_zone_name}.b-cdn.net"
        )
      rescue => error
        Result.new(provider: "Bunny", error: error.message)
      end

      private

      STORAGE_HOSTS = {
        "de" => "storage.bunnycdn.com",
        "la" => "la.storage.bunnycdn.com",
        "ny" => "la.storage.bunnycdn.com",
        "sg" => "sg.storage.bunnycdn.com",
        "syd" => "syd.storage.bunnycdn.com"
      }

      def upload(file)
        relative_path = file.delete_prefix("#{@path}/")
        uri = URI("https://#{storage_host}/#{@configuration.storage_zone_name}/#{relative_path}")

        request = Net::HTTP::Put.new(uri)
        request["AccessKey"] = @configuration.storage_zone_password

        File.open(file, "rb") do |file|
          request.body = file.read
        end

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        return if response.code.to_i == 201

        raise DeploymentError, "Bunny upload error: #{response.code} #{response.body}"
      end

      def storage_host
        STORAGE_HOSTS[@configuration.region] || STORAGE_HOSTS["de"]
      end
    end
  end
end
