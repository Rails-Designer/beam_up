# frozen_string_literal: true

require "tmpdir"

module BeamUp
  module Providers
    class GitHubPages < Base
      class Config
        def self.config_keys = %w[token branch]

        attr_accessor :token, :branch

        def initialize
          @branch = "gh-pages"
        end

        def with(options)
          self.token = options[:token]
          self.branch = options[:branch] || "gh-pages"
          self
        end

        def validate! = nil
      end

      def deploy!(path)
        @path = path

        verify_git_installed
        owner, repo = parse_remote_url(current_remote_url)

        Dir.mktmpdir do |directory|
          copy_files_to(directory)
          run_git(directory, "init")
          add_origin_remote(directory, owner, repo)
          git_commit(directory)
          git_push(directory)
        end

        Result.new(
          provider: "GitHub Pages",
          deploy_id: Time.now.to_i.to_s,
          url: pages_url(owner, repo)
        )
      rescue => error
        Result.new(provider: "GitHub Pages", error: error.message)
      end

      private

      def verify_git_installed
        raise ConfigurationError, "Git must be installed to deploy to GitHub Pages" unless system("git", "--version", out: File::NULL, err: File::NULL)
      end

      def current_remote_url
        output = `git remote get-url origin 2>/dev/null`.strip
        raise ConfigurationError, "Could not detect GitHub remote. Ensure you are in a git repository with an origin remote." if output.empty?

        output
      end

      def parse_remote_url(url)
        if url.start_with?("https://")
          parts = url.delete_prefix("https://").delete_prefix("github.com/").split("/")
          owner = parts[0]
          repo = parts[1].to_s.delete_suffix(".git").delete_suffix("/")
        elsif url.start_with?("git@github.com:")
          parts = url.delete_prefix("git@github.com:").split("/")
          owner = parts[0]
          repo = parts[1].to_s.delete_suffix(".git").delete_suffix("/")
        else
          raise ConfigurationError, "Unsupported remote URL format: #{url}"
        end

        [owner, repo]
      end

      def copy_files_to(directory)
        files_to_deploy.each do |file|
          relative_path = file.sub("#{@path}/", "")
          target_path = File.join(directory, relative_path)

          FileUtils.mkdir_p(File.dirname(target_path))
          FileUtils.cp(file, target_path)
        end
      end

      def add_origin_remote(directory, owner, repo)
        remote_url = if @configuration.token
          "https://#{@configuration.token}@github.com/#{owner}/#{repo}.git"
        else
          "https://github.com/#{owner}/#{repo}.git"
        end

        run_git(directory, "remote", "add", "origin", remote_url)
      end

      def git_commit(directory)
        run_git(directory, "add", ".")
        run_git(directory, "commit", "-m", "Deploy #{Time.now}")
      end

      def git_push(directory)
        run_git(directory, "push", "--force", "origin", "HEAD:#{@configuration.branch}")
      end

      def run_git(dir, *args)
        command = ["git", "-C", dir, *args]
        result = system(*command)

        raise DeploymentError, "Git command failed: #{command.join(" ")}" unless result
      end

      def pages_url(owner, repo) = "https://#{owner}.github.io/#{repo}/"
    end
  end
end
