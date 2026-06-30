# frozen_string_literal: true

require "test_helper"

module BeamUp
  module Providers
    class GitHubPagesTest < Minitest::Test
      def test_config_defaults
        config = GitHubPages::Config.new

        assert_equal "gh-pages", config.branch
        assert_nil config.token
      end

      def test_config_accepts_custom_branch_and_token
        config = GitHubPages::Config.new
        config.with(token: "ghp_secret", branch: "docs")

        assert_equal "ghp_secret", config.token
        assert_equal "docs", config.branch
      end

      def test_parse_https_remote_url
        provider = GitHubPages.new(GitHubPages::Config.new)

        owner, repo = provider.send(:parse_remote_url, "https://github.com/railsdesigner/beam_up.git")

        assert_equal "railsdesigner", owner
        assert_equal "beam_up", repo
      end

      def test_parse_https_remote_url_with_trailing_slash
        provider = GitHubPages.new(GitHubPages::Config.new)

        owner, repo = provider.send(:parse_remote_url, "https://github.com/railsdesigner/beam_up/")

        assert_equal "railsdesigner", owner
        assert_equal "beam_up", repo
      end

      def test_parse_ssh_remote_url
        provider = GitHubPages.new(GitHubPages::Config.new)

        owner, repo = provider.send(:parse_remote_url, "git@github.com:railsdesigner/beam_up.git")

        assert_equal "railsdesigner", owner
        assert_equal "beam_up", repo
      end

      def test_pages_url
        provider = GitHubPages.new(GitHubPages::Config.new)

        assert_equal "https://railsdesigner.github.io/beam_up/", provider.send(:pages_url, "railsdesigner", "beam_up")
      end
    end
  end
end
