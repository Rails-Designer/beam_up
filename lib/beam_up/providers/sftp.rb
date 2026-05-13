# frozen_string_literal: true

module BeamUp
  module Providers
    class SFTP < Base
      class Config
        def self.config_keys = %w[host port username password key remote_path]

        attr_accessor :host, :port, :username, :password, :key, :remote_path

        def with(options)
          self.host = options[:host]
          self.port = options[:port] || 22
          self.username = options[:username]
          self.password = options[:password]
          self.key = options[:key]
          self.remote_path = options[:remote_path]
          self
        end

        def validate!
          raise ConfigurationError, "Host must be set" unless host
          raise ConfigurationError, "Username must be set" unless username
          raise ConfigurationError, "Remote path must be set" unless remote_path
          raise ConfigurationError, "Password or key must be set" unless password || key
        end
      end

      def deploy!(path)
        @path = path

        require "net/ssh"
        require "net/sftp"

        options = {
          password: @configuration.password,
          encryption: ["aes256-gcm@openssh.com", "aes256-ctr", "aes192-ctr", "aes128-ctr", "twofish256-ctr", "twofish192-ctr", "twofish128-ctr"]
        }
        options[:keys] = [@configuration.key] if @configuration.key

        Net::SFTP.start(@configuration.host, @configuration.username, options) do |sftp|
          files_to_deploy.each do |file|
            upload sftp, file
          end
        end

        Result.new(
          provider: "SFTP",
          deploy_id: Time.now.to_i.to_s,
          url: "sftp://#{@configuration.host}#{@configuration.remote_path}"
        )
      rescue LoadError
        raise ConfigurationError, "SFTP requires net-ssh and net-sftp gems. Install with: gem install net-ssh net-sftp (or add to Gemfile)"
      rescue => error
        Result.new(provider: "SFTP", error: error.message)
      end

      private

      def upload(sftp, file)
        remote_path = File.join(@configuration.remote_path, file.delete_prefix("#{@path}/"))

        return if unchanged?(sftp, file, remote_path)

        sftp.upload(file, remote_path)
      end

      def unchanged?(sftp, file, remote_path)
        size = File.size(file)

        begin
          remote_stat = sftp.stat!(remote_path)

          remote_stat.size == size
        rescue Net::SFTP::StatusException
          false
        end
      end
    end
  end
end
