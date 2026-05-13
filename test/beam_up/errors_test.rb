# frozen_string_literal: true

require "test_helper"

module BeamUp
  class ErrorsTest < Minitest::Test
    def test_configuration_error_is_standard_error
      assert ConfigurationError < StandardError
    end

    def test_configuration_error_can_be_raised_with_message
      error = assert_raises(ConfigurationError) do
        raise ConfigurationError, "Provider must be set"
      end

      assert_equal "Provider must be set", error.message
    end

    def test_deployment_error_is_standard_error
      assert DeploymentError < StandardError
    end

    def test_deployment_error_can_be_raised_with_message
      error = assert_raises(DeploymentError) do
        raise DeploymentError, "Failed to upload file"
      end

      assert_equal "Failed to upload file", error.message
    end

    def test_configuration_error_can_be_caught_as_standard_error
      begin
        raise ConfigurationError, "test"
      rescue StandardError => error
        error = error
      end

      assert_instance_of ConfigurationError, error
    end

    def test_deployment_error_can_be_caught_as_standard_error
      begin
        raise DeploymentError, "test"
      rescue StandardError => error
        error = error
      end

      assert_instance_of DeploymentError, error
    end
  end
end
