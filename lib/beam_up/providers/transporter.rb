# frozen_string_literal: true

require "fileutils"

module BeamUp
  module Providers
    class Transporter < Base
      class Config
        def self.config_keys = %w[target_directory]

        attr_accessor :target_directory

        def with(options)
          self.target_directory = options[:target_directory]
          self
        end

        def validate!
          raise ConfigurationError, "Target directory must be set" unless target_directory
        end
      end

      def deploy!(path)
        @path = path
        files = files_to_deploy

        puts "Energizing… 🚀"
        puts "Matter stream detected: #{files.length} files"

        FileUtils.mkdir_p(@configuration.target_directory)

        files.each do |file|
          relative_path = file.sub("#{@path}/", "")
          target_path = File.join(@configuration.target_directory, relative_path)

          FileUtils.mkdir_p(File.dirname(target_path))
          FileUtils.cp(file, target_path)

          puts "  Beaming: #{relative_path}"
        end

        puts "Transport complete. Files materialized at: #{@configuration.target_directory}"

        Result.new(
          provider: "Transporter",
          deploy_id: files.length.to_s,
          url: @configuration.target_directory
        )
      rescue => error
        Result.new(provider: "Transporter", error: error.message)
      end
    end
  end
end
