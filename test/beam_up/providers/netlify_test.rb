# frozen_string_literal: true

require "test_helper"

module BeamUp
  module Providers
    class NetlifyTest < Minitest::Test
      def setup
        @config = Netlify::Config.new
        @config.api_token = "test_token"
      end

      def test_project_id_treats_empty_string_as_missing
        @config.project_id = ""
        netlify = Netlify.new(@config)

        assert_raises(DeploymentError) do
          netlify.send(:project_id)
        end
      end

      def test_message_shows_new_site_info_when_project_id_was_empty
        @config.project_id = ""
        netlify = Netlify.new(@config)
        netlify.instance_variable_set(:@created_project_id, "new-site-123")

        result = netlify.send(:message)

        assert_includes result, "new-site-123"
        assert_includes result, "New site created"
        assert_includes result, ".beam_up.yml"
      end

      def test_message_shows_simple_success_when_project_id_was_set
        @config.project_id = "existing-site-id"
        netlify = Netlify.new(@config)

        result = netlify.send(:message)

        assert_equal "Successfully deployed to Netlify", result
      end
    end
  end
end
