# frozen_string_literal: true

require "test_helper"

module BeamUp
  class ConfigurationTest < Minitest::Test
    def setup
      @config = Configuration.new
    end

    def test_provider_accessor
      @config.provider = "netlify"

      assert_equal "netlify", @config.provider
    end

    def test_path_accessor
      @config.path = "./output"

      assert_equal "./output", @config.path
    end

    def test_provider_config_returns_config_object
      @config.provider = "netlify"

      provider_config = @config.provider_config

      assert_instance_of Providers::Netlify::Config, provider_config
    end

    def test_provider_config_caches_result
      @config.provider = "netlify"

      first = @config.provider_config
      second = @config.provider_config

      assert_same first, second
    end

    def test_provider_config_raises_on_unknown_provider
      @config.provider = "unknown_provider"

      assert_raises(ConfigurationError) do
        @config.provider_config
      end
    end

    def test_validate_raises_when_provider_nil
      @config.provider = nil

      error = assert_raises(ConfigurationError) do
        @config.validate!
      end

      assert_equal "Provider must be set", error.message
    end

    def test_validate_raises_when_provider_empty
      @config.provider = ""

      error = assert_raises(ConfigurationError) do
        @config.validate!
      end

      assert_equal "Provider must be set", error.message
    end

    def test_validate_passes_when_provider_set
      @config.provider = "netlify"
      @config.netlify.api_token = "test_token"

      @config.validate!
    end

    def test_validate_delegates_to_provider_config
      @config.provider = "netlify"

      error = assert_raises(ConfigurationError) do
        @config.validate!
      end

      assert_equal "API token must be set", error.message
    end

    def test_method_missing_returns_provider_config
      netlify_config = @config.netlify

      assert_instance_of Providers::Netlify::Config, netlify_config
    end

    def test_method_missing_returns_same_instance_on_multiple_calls
      first = @config.bunny
      second = @config.bunny

      assert_same first, second
    end

    def test_method_missing_raises_no_method_error_for_invalid_provider
      assert_raises(NoMethodError) do
        @config.invalid_provider
      end
    end

    def test_respond_to_with_valid_provider
      assert @config.respond_to?(:netlify)
      assert @config.respond_to?(:bunny)
      assert @config.respond_to?(:aws_s3)
    end

    def test_respond_to_with_invalid_provider
      refute @config.respond_to?(:invalid_provider)
    end

    def test_respond_to_delegates_to_super_for_standard_methods
      assert @config.respond_to?(:provider)
      assert @config.respond_to?(:provider=)
      assert @config.respond_to?(:validate!)
    end

    def test_before_actions_accessor
      @config.before_actions = ["bundle exec rake build"]

      assert_equal ["bundle exec rake build"], @config.before_actions
    end

    def test_after_actions_accessor
      @config.after_actions = ["bundle exec rake clean"]

      assert_equal ["bundle exec rake clean"], @config.after_actions
    end

    def test_timeout_has_default_value
      assert_equal 300, @config.timeout
    end

    def test_timeout_accessor
      @config.timeout = 600

      assert_equal 600, @config.timeout
    end
  end
end
