# frozen_string_literal: true

module BeamUp
  class Core
    class Deploy
      def self.call(config, path)
        new(config, path).call
      end

      def initialize(config, path)
        @config, @path = config, path
      end

      def call
        deploy_path = @path || @config.path || raise(ConfigurationError, "No path specified")

        @config.validate!

        provider_class = PROVIDERS[@config.provider.to_s] || raise(ConfigurationError, "Unknown provider: #{@config.provider}")

        provider_class.new(@config.provider_config).deploy!(deploy_path)
      end
    end
  end
end
