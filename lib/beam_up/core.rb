# frozen_string_literal: true

require "yaml"
require "beam_up/core/init"
require "beam_up/core/deploy"

module BeamUp
  class Core
    class << self
      def configure(&block)
        yield(configuration)
      end

      attr_writer :config_file

      def configuration(config_file: nil)
        @configuration ||= begin
          custom_path = config_file || @config_file || ((@configuration&.config_file && File.exist?(@configuration.config_file)) ? @configuration.config_file : nil)
          config = custom_path ? configuration_file(custom_path) : configuration_file

          config || raise(ConfigurationError, "No configuration found. Run `beam_up init` to create one.")
        end
      end

      def deploy!(path = nil, provider: nil, config_file: nil)
        config = config(path, provider, config_file)
        config.provider = provider if provider

        execute! config.before_actions

        Core::Deploy.call(config, path).tap do
          execute! config.after_actions
        end
      end

      private

      def config(path, provider, config_file)
        config = load!(config_file)

        return config if config&.provider

        if path && provider.nil?
          PROVIDERS["seal_static"].onboarding_init!(config_file: config_file)

          config = load!(config_file)
          raise ConfigurationError, "Failed to create configuration after onboarding" if config.nil?

          config
        else
          raise ConfigurationError, "No configuration found. Run `beam_up init` to create one."
        end
      end

      def load!(config_file)
        if config_file
          configuration_file(config_file)
        elsif @config_file
          configuration_file(@config_file)
        else
          configuration_file
        end
      end

      def configuration_file(custom_path = nil)
        file = custom_path || ["config/beam_up.yml", ".beam_up.yml"].find { File.exist?(it) }

        return nil unless file && File.exist?(file)

        data = YAML.safe_load_file(file)

        Configuration.new.tap do |config|
          config.provider = data["provider"]
          config.path = data["path"]
          config.timeout = data["timeout"] || Configuration::DEFAULT_TIMEOUT
          config.before_actions = data["before_actions"] || []
          config.after_actions = data["after_actions"] || []

          PROVIDERS.each_key do |provider_name|
            if (provider_data = data[provider_name])
              config.send(provider_name).with(provider_data.transform_keys(&:to_sym))
            end
          end
        end
      end

      def execute!(actions)
        return if actions.nil? || actions.empty?

        actions.each do |action|
          result = system(action)

          raise ConfigurationError, "Before action failed: #{action}" unless result
        end
      end
    end
  end
end
