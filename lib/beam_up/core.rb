# frozen_string_literal: true

require "yaml"

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

          config || raise(ConfigurationError, "No .beam_up.yml found. Run `beam_up init PROVIDER` to create one.")
        end
      end

      def deploy!(path = nil, provider: nil, config_file: nil)
        config = configuration(config_file: config_file)
        config.provider = provider if provider

        deploy_path = path || config.path || raise(ConfigurationError, "No path specified")

        config.validate!

        execute! config.before_actions

        provider_class = PROVIDERS[config.provider.to_s] || raise(ConfigurationError, "Unknown provider: #{config.provider}")
        result = provider_class.new(config.provider_config).deploy! deploy_path

        execute! config.after_actions

        result
      end

      def init!(provider, config_file: nil)
        raise ConfigurationError, "Unknown provider: #{provider}" unless PROVIDERS.key?(provider)

        config_file ||= ["config/beam_up.yml", ".beam_up.yml"].find { File.exist?(it) }
        config_file ||= ".beam_up.yml"

        if File.exist?(config_file)
          data = YAML.safe_load_file(config_file) || {}

          raise ConfigurationError, "Provider '#{provider}' already configured in #{config_file}" if data.key?(provider)

          section = YAML.dump({provider => PROVIDERS[provider]::Config.config_keys.to_h { [it, ""] }}, indent: 2, line_width: 80).sub(/^---\n/, "")
          File.write(config_file, File.read(config_file) + "\n" + section)
        else
          yaml = YAML.dump({
            "provider" => provider,
            "path" => nil,
            provider => PROVIDERS[provider]::Config.config_keys.to_h { |key| [key, ""] }
          }, indent: 2, line_width: 80).gsub(/^path:$/, "# path: ./output # uncomment to set a default folder")

          File.write(config_file, yaml)
        end

        config_file
      end

      private

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
