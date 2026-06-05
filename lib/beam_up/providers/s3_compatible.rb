# frozen_string_literal: true

require "aws-sdk-s3"

module BeamUp
  module Providers
    class S3Compatible < Base
      def deploy!(path)
        @path = path

        files = files_to_deploy
        BeamUp.progress&.start(type: :files, total: files.count)

        files.each do |file|
          upload file.delete_prefix("#{@path}/"), file
          BeamUp.progress&.tick
        end

        Result.new(
          provider: provider_name,
          deploy_id: Time.now.to_i.to_s,
          url: public_url
        )
      rescue => error
        Result.new(provider: provider_name, error: error.message)
      ensure
        BeamUp.progress&.finish
      end

      private

      def upload(key, file)
        File.open(file, "rb") do |opened_file|
          s3_client.put_object(
            bucket: bucket_name,
            key: key,
            body: opened_file,
            acl: "public-read"
          )
        end
      end

      def s3_client
        @s3_client ||= Aws::S3::Client.new(
          access_key_id: @configuration.access_key,
          secret_access_key: @configuration.secret_key,
          region: @configuration.region,
          endpoint: endpoint
        )
      end

      def bucket_name
        raise NotImplementedError, "Subclasses must implement #bucket_name"
      end

      def endpoint
        raise NotImplementedError, "Subclasses must implement #endpoint"
      end

      def public_url
        raise NotImplementedError, "Subclasses must implement #public_url"
      end

      def provider_name
        raise NotImplementedError, "Subclasses must implement #provider_name"
      end
    end
  end
end
