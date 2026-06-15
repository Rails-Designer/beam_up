# frozen_string_literal: true

require "yaml"
require "tty-prompt"

module BeamUp
  class Core
    class Init
      def self.call(provider = nil, config_file: nil, values: {})
        new(provider, config_file: config_file, values: values).call
      end

      def initialize(provider, config_file: nil, values: {})
        @provider = provider
        @config_file = config_file
        @values = values
      end

      def call
        @provider ||= prompt
        raise ConfigurationError, "Unknown provider: #{@provider}. Available: #{default_list.join(", ")}" unless PROVIDERS.key?(@provider)

        @config_file ||= ["config/beam_up.yml", ".beam_up.yml"].find { File.exist?(it) }
        @config_file ||= ".beam_up.yml"

        raise ConfigurationError, "Provider '#{@provider}' already configured in #{@config_file}" if configured?

        keys = PROVIDERS[@provider]::Config.config_keys
        values = if @values.any?
          @values
        elsif $stdout.tty? && !ENV["TTY_TEST"]
          keys.to_h { |key| [key, TTY::Prompt.new.ask("#{key}:") { it.required false }.to_s] }
        else
          {}
        end

        configured = keys.to_h { [it, values[it].to_s] }

        if File.exist?(@config_file)
          Configuration.append(@config_file, provider: @provider, config: configured)
        else
          Configuration.create(@config_file, provider: @provider, config: configured)
        end

        @config_file
      end

      private

      def prompt
        raise ConfigurationError, "No provider specified. Available: #{default_list.join(", ")}" unless $stdout.tty? && !ENV["TTY_TEST"]

        providers = default_list.reject { it == "transporter" }

        TTY::Prompt.new.select("Select a provider:", per_page: providers.size) do |menu|
          providers.each { menu.choice display_name(it), it }
        end
      end

      def default_list
        PROVIDERS.keys.sort.tap { it.unshift(it.delete("seal_static")) }
      end

      def configured?
        return false unless File.exist?(@config_file)

        (YAML.safe_load_file(@config_file) || {}).key?(@provider)
      end

      def display_name(key)
        name = PROVIDERS[key].display_name

        (key == "seal_static") ? "#{name} (recommended)" : name
      end
    end
  end
end
