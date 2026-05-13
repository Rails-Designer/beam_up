# frozen_string_literal: true

require "test_helper"

module BeamUp
  class ResultTest < Minitest::Test
    def test_success_with_no_error
      result = Result.new(provider: "Netlify", deploy_id: "123")

      assert result.success?
      refute result.failure?
    end

    def test_success_with_error
      result = Result.new(provider: "Netlify", error: "Something went wrong")

      refute result.success?
      assert result.failure?
    end

    def test_error_message_format
      result = Result.new(provider: "Netlify", error: "Deployment failed")

      assert_includes result.message, "Deployment to Netlify failed"
      assert_includes result.message, "Deployment failed"
    end

    def test_success_message_format_with_url
      result = Result.new(provider: "Netlify", url: "https://example.com")

      assert_includes result.message, "Successfully deployed to Netlify"
      assert_includes result.message, "https://example.com"
    end

    def test_success_message_format_without_url
      result = Result.new(provider: "Netlify")

      assert_includes result.message, "Successfully deployed to Netlify"
    end
  end
end
