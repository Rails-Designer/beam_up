# frozen_string_literal: true

require "beam_up/result"

module BeamUp
  module Providers
    class Base
      def initialize(configuration)
        @configuration = configuration

        configuration.validate!
      end

      def deploy!
        raise NotImplementedError, "Subclasses must implement #deploy"
      end

      private

      def files_to_deploy
        Dir.glob("#{@path}/**/*").select { File.file?(it) }
      end
    end
  end
end
