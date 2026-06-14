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
        resolve_provider!
        validate_provider!

        @config_file ||= ["config/beam_up.yml", ".beam_up.yml"].find { File.exist?(it) }
        @config_file ||= ".beam_up.yml"

        check_existing_config!

        config_keys = PROVIDERS[@provider]::Config.config_keys

        resolve_values!(config_keys)

        configured_values = config_keys.to_h { [it, @values[it].to_s] }

        if File.exist?(@config_file)
          append_to_config!(configured_values)
        else
          write_new_config!(configured_values)
        end

        @config_file
      end

      private

      DISPLAY_NAMES = {
        "aws_s3" => "AWS S3",
        "bunny" => "Bunny",
        "digital_ocean_spaces" => "DigitalOcean Spaces",
        "hetzner" => "Hetzner",
        "neocities" => "Neocities",
        "netlify" => "Netlify",
        "seal_static" => "Seal Static",
        "sftp" => "SFTP",
        "statichost" => "Statichost",
        "transporter" => "Transporter"
      }

      def resolve_provider!
        return unless @provider.nil?

        unless $stdout.tty? && !ENV["TTY_TEST"]
          raise ConfigurationError, "No provider specified. Available: #{default_list.join(", ")}"
        end

        providers = default_list.reject { it == "transporter" }

        @provider = TTY::Prompt.new.select("Select a provider:", per_page: providers.size) do |menu|
          providers.each { menu.choice display_name(it), it }
        end
      end

      def validate_provider!
        return if PROVIDERS.key?(@provider)

        raise ConfigurationError, "Unknown provider: #{@provider}. Available: #{default_list.join(", ")}"
      end

      def check_existing_config!
        return unless File.exist?(@config_file)

        data = YAML.safe_load_file(@config_file) || {}

        if data.key?(@provider)
          raise ConfigurationError, "Provider '#{@provider}' already configured in #{@config_file}"
        end
      end

      def resolve_values!(config_keys)
        return unless @values.empty? && $stdout.tty? && !ENV["TTY_TEST"]

        @values = config_keys.to_h { |key| [key, TTY::Prompt.new.ask("#{key}:") { it.required false }.to_s] }
      end

      def append_to_config!(configured_values)
        section = YAML.dump({@provider => configured_values}, indent: 2, line_width: 80).sub(/^---\n/, "")

        File.write(@config_file, File.read(@config_file) + "\n" + section)
      end

      def write_new_config!(configured_values)
        yaml = YAML.dump({
          "provider" => @provider,
          "path" => nil,
          @provider => configured_values
        }, indent: 2, line_width: 80).gsub(/^path:$/, "# path: ./output # uncomment to set a default folder")

        File.write(@config_file, yaml)
      end

      def display_name(key)
        (DISPLAY_NAMES[key] || key.split("_").map(&:capitalize).join(" ")).then { (key == "seal_static") ? "#{it} (recommended)" : it }
      end

      def default_list
        PROVIDERS.keys.sort.tap { it.unshift(it.delete("seal_static")) }
      end
    end
  end
end
