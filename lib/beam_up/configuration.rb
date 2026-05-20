# frozen_string_literal: true

module BeamUp
  class Configuration
    attr_accessor :provider, :path, :before_actions, :after_actions, :timeout, :config_file

    DEFAULT_TIMEOUT = 300  # 5 minutes

    def initialize
      @providers = {}
      @timeout = DEFAULT_TIMEOUT
    end

    def self.with(options)
      new.tap do |config|
        config.provider = options[:provider]
        config.provider_config.with(options)
      end
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
