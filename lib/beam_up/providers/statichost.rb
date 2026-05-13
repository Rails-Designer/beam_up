# frozen_string_literal: true

require "net/http"
require "zip"
require "tempfile"

module BeamUp
  module Providers
    class Statichost < Base
      BUILDER_HOST = "https://builder.statichost.eu"

      class Config
        def self.config_keys = %w[api_key site_name builder_host]

        attr_accessor :api_key, :site_name, :builder_host

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

        zipped_file = create_zip path
        response = upload zipped_file

        Result.new(
          provider: "Statichost",
          deploy_id: response["id"] || Time.now.to_i.to_s,
          url: "https://#{@configuration.site_name}.statichost.eu"
        )
      rescue => error
        Result.new(provider: "Statichost", error: error.message)
      ensure
        zipped_file&.close!
      end

      private

      def create_zip(path)
        temp = Tempfile.new(["statichost", ".zip"], binmode: true)

        Zip::OutputStream.open(temp) do |zip|
          Dir.glob("#{path}/**/*").each do |file|
            next unless File.file?(file)

            relative_path = file.delete_prefix("#{path}/")
            zip.put_next_entry(relative_path)
            zip.write(File.read(file))
          end
        end

        temp.rewind
        temp
      end

      def upload(zipped_file)
        uri = URI("https://builder.statichost.eu/#{@configuration.site_name}/drop")

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{@configuration.api_key}"
        request["Content-Type"] = "application/zip"
        request["Accept"] = "application/json"
        request.body = zipped_file.read

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        case response.code.to_i
        when 200..299
          response.body.empty? ? {} : JSON.parse(response.body)
        else
          raise DeploymentError, "Statichost API error: #{response.code} #{response.body}"
        end
      end
    end
  end
end
