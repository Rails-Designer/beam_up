# frozen_string_literal: true

require "erb"

module BeamUp
  class Configuration
    attr_accessor :provider, :path, :before_actions, :after_actions, :timeout, :config_file

    DEFAULT_TIMEOUT = 300  # 5 minutes

    def initialize
      @providers, @timeout = {}, DEFAULT_TIMEOUT
    end

    def self.with(options)
      new.tap do |config|
        config.provider = options[:provider]
        config.provider_config.with(options)
      end
    end

    def self.create(path, provider:, config:)
      yaml = YAML.dump({
        "provider" => provider,
        "path" => nil,
        provider => config
      }, indent: 2, line_width: 80).gsub(/^path:$/, "# path: ./output # uncomment to set a default folder")

      File.write(path, yaml)
    end

    def self.append(path, provider:, config:)
      raw = File.read(path)
      content = raw.sub(/\A---\n/, "")
      data = if path.end_with?(".yml.erb")
        YAML.safe_load(ERB.new(content, trim_mode: "-").result) || {}
      else
        YAML.safe_load(content) || {}
      end

      unless data.key?("provider")
        content = "provider: #{provider}\n#{content}"
      end

      File.write(path, content.rstrip + "\n" + "#{provider}:\n#{config.map { |key, value| "  #{key}: #{value}" }.join("\n")}\n")
    end

    def provider_config
      raise(ConfigurationError, "Provider must be set") if provider.nil? || provider.empty?

      provider_class = PROVIDERS[provider.to_s]
      raise(ConfigurationError, "Unknown provider: #{provider}") unless provider_class

      @providers[provider.to_s] ||= provider_class::Config.new
    end

    def validate!
      raise ConfigurationError, "Provider must be set" unless provider

      provider_config.validate!
    end

    def method_missing(method_name, *arguments)
      if PROVIDERS.key?(method_name.to_s)
        @providers[method_name.to_s] ||= PROVIDERS[method_name.to_s]::Config.new
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      PROVIDERS.key?(method_name.to_s) || super
    end
  end
end
