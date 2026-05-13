# frozen_string_literal: true

require "yaml"

module BeamUp
  class Core
    class << self
      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= configuration_file || raise(ConfigurationError, "No .beam_up.yml found. Run `beam_up init PROVIDER` to create one.")
      end

      def deploy!(path = nil, provider: nil)
        config = configuration_file
        config.provider = provider if provider

        deploy_path = path || config.path || raise(ConfigurationError, "No path specified")

        config.validate!

        execute! config.before_actions

        provider_class = PROVIDERS[config.provider.to_s] || raise(ConfigurationError, "Unknown provider: #{config.provider}")
        result = provider_class.new(config.provider_config).deploy! deploy_path

        execute! config.after_actions

        result
      end

      private

      def configuration_file
        file = ["config/beam_up.yml", ".beam_up.yml"].find { File.exist?(it) }
        return nil unless file

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
