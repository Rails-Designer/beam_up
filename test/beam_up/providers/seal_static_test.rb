# frozen_string_literal: true

require "test_helper"

module BeamUp
  module Providers
    class SealStaticTest < Minitest::Test
      def setup
        @config = SealStatic::Config.new
      end

      def test_config_keys_includes_api_key
        assert_equal %w[api_key], SealStatic::Config.config_keys
      end

      def test_config_with_sets_api_key
        @config.with(api_key: "sk_live_123")
        assert_equal "sk_live_123", @config.api_key
      end

      def test_config_validate_passes_when_api_key_set
        @config.api_key = "sk_live_123"
        @config.validate!
      end

      def test_config_validate_raises_when_api_key_empty
        @config.api_key = ""
        assert_raises(ConfigurationError) do
          @config.validate!
        end
      end

      def test_config_validate_raises_when_api_key_nil
        @config.api_key = nil
        assert_raises(ConfigurationError) do
          @config.validate!
        end
      end

      def test_provider_class_exists
        assert defined?(SealStatic)
      end

      def test_has_base_url_constant
        assert_equal "https://app.sealstatic.com/api", SealStatic::BASE_URL
      end
    end
  end
end