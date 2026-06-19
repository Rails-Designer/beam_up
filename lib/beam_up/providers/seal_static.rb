# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "zip"
require "tempfile"
require "tty-prompt"

module BeamUp
  module Providers
    class SealStatic < Base
      def self.display_name = "Seal Static"

      BASE_URL = "https://app.sealstatic.com/api"

      class << self
        def onboarding_init!(config_file: nil, email: nil, token: nil)
          prompt = TTY::Prompt.new

          email ||= prompt.ask("Email address:") { |q| q.required(true) }
          request_token(email)

          token ||= prompt.ask("Verification token:") { |q| q.required(true) }

          result = create_project(token)
          raise ConfigurationError, "Seal Static: #{result["error"]}" if result["error"]

          create_config(result, config_file)

          result
        end

        def request_token(email)
          uri = URI("#{BASE_URL}/onboarding/tokens")

          request = Net::HTTP::Post.new(uri)
          request["Content-Type"] = "application/json"
          request["Accept"] = "application/json"
          request.body = JSON.generate(email_address: email)

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

          case response.code.to_i
          when 200
            body = JSON.parse(response.body)
            raise ConfigurationError, "Seal Static: #{body["error"]}" if body["error"]

            puts body["message"] if body["message"]
          when 422
            body = JSON.parse(response.body)
            raise ConfigurationError, "Seal Static: #{body["error"]}"
          when 429
            raise ConfigurationError, "Seal Static: Rate limit exceeded. Please wait before trying again."
          else
            raise ConfigurationError, "Seal Static API error: #{response.code} #{response.body}"
          end
        end

        def create_project(token)
          uri = URI("#{BASE_URL}/onboarding/projects")

          request = Net::HTTP::Post.new(uri)
          request["Content-Type"] = "application/x-www-form-urlencoded"
          request["Accept"] = "application/json"
          request.body = URI.encode_www_form(token: token)

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

          case response.code.to_i
          when 200
            JSON.parse(response.body)
          when 401
            body = JSON.parse(response.body)
            raise ConfigurationError, "Seal Static: #{body["error"]}"
          when 429
            raise ConfigurationError, "Seal Static: Rate limit exceeded."
          else
            raise ConfigurationError, "Seal Static API error: #{response.code} #{response.body}"
          end
        end

        private

        def create_config(result, config_file = nil)
          config_file ||= ["config/beam_up.yml", ".beam_up.yml"].find { File.exist?(it) }
          config_file ||= ".beam_up.yml"

          if File.exist?(config_file)
            Configuration.append(config_file, provider: "seal_static", config: {"api_key" => result["api_key"]})
          else
            Configuration.create(config_file, provider: "seal_static", config: {"api_key" => result["api_key"]})
          end

          puts "Configuration saved to #{config_file}"
        end
      end

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

        files = files_to_deploy
        BeamUp.progress&.start(type: :files, total: files.count)
        zipped_file = create_zip(path, files)
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

      def create_zip(path, files)
        temporary_file = Tempfile.new(["seal_static", ".zip"], binmode: true)

        Zip::OutputStream.open(temporary_file) do |zip|
          files.each do |file|
            relative_path = file.delete_prefix("#{path}/")

            zip.put_next_entry(relative_path)
            zip.write(File.read(file))

            BeamUp.progress&.tick
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
