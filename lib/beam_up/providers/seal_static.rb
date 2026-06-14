# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "zip"
require "tempfile"

module BeamUp
  module Providers
    class SealStatic < Base
      def self.display_name = "Seal Static"

      BASE_URL = "https://app.sealstatic.com/api"

      class Config
        def self.config_keys = %w[api_key]

        attr_accessor :api_key

        def with(options)
          self.api_key = options[:api_key]
          self
        end

        def validate!
          raise ConfigurationError, "API key must be set" if api_key.nil? || api_key.empty?
        end
      end

      def deploy!(path)
        @path = path

        zipped_file = create_zip(path)
        BeamUp.progress&.start(type: :bytes, total: zipped_file.size)
        response = upload zipped_file

        return Result.new(provider: "Seal Static", error: response["error"]) if response["error"]

        Result.new(
          provider: "Seal Static",
          url: response["url"]
        )
      rescue => error
        Result.new(provider: "Seal Static", error: error.message)
      ensure
        BeamUp.progress&.finish
        zipped_file&.close!
      end

      private

      def create_zip(path)
        temporary_file = Tempfile.new(["seal_static", ".zip"], binmode: true)

        Zip::OutputStream.open(temporary_file) do |zip|
          files_to_deploy.each do |file|
            relative_path = file.delete_prefix("#{path}/")

            zip.put_next_entry(relative_path)
            zip.write(File.read(file))
          end
        end

        temporary_file.rewind
        temporary_file
      end

      def upload(zipped_file)
        uri = URI("#{BASE_URL}/uploads")

        boundary = "----BeamUpBoundary#{SecureRandom.hex(16)}"
        body = multipart_body(boundary, zipped_file)

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{@configuration.api_key}"
        request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
        request["Accept"] = "application/json"
        request.body = body

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

        case response.code.to_i
        when 200..299
          response.body.empty? ? {} : JSON.parse(response.body)
        else
          raise DeploymentError, "Seal Static API error: #{response.code} #{response.body}"
        end
      end

      def multipart_body(boundary, zipped_file)
        content = zipped_file.read
        filename = "site.zip"

        parts = []
        parts << "--#{boundary}\r\n"
        parts << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
        parts << "Content-Type: application/zip\r\n"
        parts << "\r\n"
        parts << content
        parts << "\r\n"
        parts << "--#{boundary}--\r\n"
        parts.join
      end
    end
  end
end
