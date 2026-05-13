# frozen_string_literal: true

require "digest"
require "cgi/escape"
require "net/http"
require "json"

module BeamUp
  module Providers
    class Netlify < Base
      class Config
        def self.config_keys = %w[api_token project_id]

        attr_accessor :api_token, :project_id

        def with(options)
          self.api_token = options[:api_token]
          self.project_id = options[:project_id]
          self
        end

        def validate!
          raise ConfigurationError, "API token must be set" unless api_token
        end
      end

      def deploy!(path)
        @path = path
        digested_files = digested files_to_deploy
        response = post "/sites/#{project_id}/deploys", files: digested_files

        upload(files_to_deploy, response)

        Result.new(
          provider: "Netlify",
          deploy_id: response["id"],
          url: response["deploy_ssl_url"] || response["ssl_url"]
        )
      rescue => error
        Result.new(provider: "Netlify", error: error.message)
      end

      private

      def digested(files)
        files.to_h do |file|
          relative_path = "/#{file.delete_prefix("#{@path}/")}"

          [relative_path, Digest::SHA1.hexdigest(File.read(file))]
        end
      end

      def project_id
        return @configuration.project_id if @configuration.project_id.to_s != ""

        site_name = "#{File.basename(Dir.pwd)}-#{Time.now.to_i}"
        site = post("/sites", {name: [site_name, SecureRandom.hex(4)].join("-")})
        @created_project_id = site["id"]
      end

      def upload(files, response)
        required_shas = response["required"] || []
        return if required_shas.empty?

        required_shas.each.with_index(1) do |sha, index|
          file_path = file_map_from(files)[sha]
          next if file_path.nil? || file_path.empty?

          relative_path = "/" + file_path.delete_prefix("#{@path}/")
          escaped_path = CGI.escape(relative_path.delete_prefix("/"))

          put("/deploys/#{response["id"]}/files/#{escaped_path}", File.read(file_path))
        end
      end

      def message
        if @configuration.project_id.to_s.empty?
          <<~MSG
            Successfully deployed to Netlify.

            New site created with ID: #{@created_project_id}
            Add this to your .beam_up.yml to skip site creation in future deploys:
              project_id: #{@created_project_id}
          MSG
        else
          "Successfully deployed to Netlify"
        end
      end

      def file_map_from(files)
        files.to_h { [Digest::SHA1.hexdigest(File.read(it)), it] }
      end

      def post(path, data)
        request(:post, path, data.to_json, "application/json")
      end

      def put(path, data)
        request(:put, path, data, "application/octet-stream")
      end

      def request(method, path, body = nil, content_type = nil)
        uri = URI("https://api.netlify.com/api/v1#{path}")

        request = case method
        when :post then Net::HTTP::Post.new(uri)
        when :put then Net::HTTP::Put.new(uri)
        end

        request["Authorization"] = "Bearer #{@configuration.api_token}"
        request["Content-Type"] = content_type if content_type
        request.body = body if body

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

        case response.code.to_i
        when 200..299
          response.body.empty? ? {} : JSON.parse(response.body)
        else
          raise DeploymentError, "Netlify API error: #{response.code} #{response.body}"
        end
      end
    end
  end
end
