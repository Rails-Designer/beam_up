# frozen_string_literal: true

require "json"
require "net/http"

module BeamUp
  module Providers
    class Neocities < Base
      API_HOST = "https://neocities.org"

      class Config
        def self.config_keys = %w[api_key site_name]

        attr_accessor :api_key, :site_name

        def with(options)
          self.api_key = options[:api_key]
          self.site_name = options[:site_name]
          self
        end

        def validate!
          raise ConfigurationError, "API key must be set" unless api_key
          raise ConfigurationError, "Site name must be set" unless site_name
        end
      end

      def deploy!(path)
        @path = path

        files = files_to_deploy
        BeamUp.progress&.start(type: :files, total: files.count)

        upload_files

        Result.new(
          provider: "Neocities",
          deploy_id: Time.now.to_i.to_s,
          url: "https://#{@configuration.site_name}.neocities.org"
        )
      rescue => error
        Result.new(provider: "Neocities", error: error.message)
      ensure
        BeamUp.progress&.finish
      end

      private

      def upload_files
        uri = URI("#{API_HOST}/api/upload")

        request = Net::HTTP::Post.new(uri)
        request.basic_auth(@configuration.site_name, @configuration.api_key)

        form_data = files_to_deploy.map do |file|
          relative_path = file.delete_prefix("#{@path}/")

          [relative_path, File.read(file)]
        end

        request.set_form(form_data, "multipart/form-data")

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        case response.code.to_i
        when 200..299
          json_response = JSON.parse(response.body)
          raise DeploymentError, json_response["message"] if json_response["result"] == "error"
        else
          raise DeploymentError, "Neocities API error: #{response.code} #{response.body}"
        end
      end
    end
  end
end
