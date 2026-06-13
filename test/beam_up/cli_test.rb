# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

module BeamUp
  class CLITest < Minitest::Test
    def setup
      @original_directory = Dir.pwd
      @temporary_directory = Dir.mktmpdir

      Dir.chdir(@temporary_directory)

      BeamUp.instance_variable_set(:@configuration, nil)
      BeamUp::Core.instance_variable_set(:@configuration, nil)
      BeamUp::Core.instance_variable_set(:@config_file, nil)
    end

    def teardown
      Dir.chdir(@original_directory)
      FileUtils.rm_rf(@temporary_directory)

      BeamUp.instance_variable_set(:@configuration, nil)
      BeamUp::Core.instance_variable_set(:@configuration, nil)
      BeamUp::Core.instance_variable_set(:@config_file, nil)
    end

    def test_init_creates_config_file
      cli = CLI.new(["init", "netlify"])

      assert_output(/Configured netlify in/) do
        cli.run
      end

      assert File.exist?(".beam_up.yml")

      config_content = File.read(".beam_up.yml")
      configuration = YAML.safe_load_file(".beam_up.yml")

      assert_equal "netlify", configuration["provider"]
      assert configuration["netlify"].key?("api_token")
      assert configuration["netlify"].key?("project_id")
      assert_includes config_content, "# path: ./output"
    end

    def test_init_with_bunny_provider
      capture_io { CLI.new(["init", "bunny"]).run }

      configuration = YAML.safe_load_file(".beam_up.yml")

      assert_equal "bunny", configuration["provider"]
      assert configuration["bunny"].key?("storage_zone_password")
      assert configuration["bunny"].key?("storage_zone_name")
      assert configuration["bunny"].key?("region")
    end

    def test_init_with_invalid_provider_shows_error
      cli = CLI.new(["init", "invalid_provider"])

      output, _ = capture_io do
        assert_raises(SystemExit) { cli.run }
      end

      assert_includes output, "Available providers:"
      assert_includes output, "aws_s3"
      assert_includes output, "netlify"
    end

    def test_init_without_provider_shows_error
      cli = CLI.new(["init"])

      output, _ = capture_io do
        assert_raises(SystemExit) { cli.run }
      end

      assert_includes output, "Available providers:"
    end

    def test_init_without_provider_can_use_prompt_selection
      cli = CLI.new(["init"])
      cli.define_singleton_method(:choose_provider) { "netlify" }

      assert_output(/Configured netlify in/) do
        cli.run
      end

      configuration = YAML.safe_load_file(".beam_up.yml")

      assert_equal "netlify", configuration["provider"]
      assert configuration["netlify"].key?("api_token")
    end

    def test_init_appends_provider_to_existing_config
      File.write(".beam_up.yml", YAML.dump({
        "provider" => "netlify",
        "path" => "./dist",
        "netlify" => {"api_token" => "existing_token", "project_id" => "existing_site"}
      }))

      assert_output(/Configured bunny in/) do
        CLI.new(["init", "bunny"]).run
      end

      configuration = YAML.safe_load_file(".beam_up.yml")

      assert_equal "netlify", configuration["provider"]
      assert_equal "./dist", configuration["path"]
      assert_equal "existing_token", configuration["netlify"]["api_token"]
      assert_equal "existing_site", configuration["netlify"]["project_id"]

      assert configuration.key?("bunny")
      assert configuration["bunny"].key?("storage_zone_password")
      assert configuration["bunny"].key?("storage_zone_name")
      assert configuration["bunny"].key?("region")
    end

    def test_init_preserves_path_comment_when_adding_second_provider
      CLI.new(["init", "bunny"]).run

      config_content_before = File.read(".beam_up.yml")
      assert_includes config_content_before, "# path: ./output"

      assert_output(/Configured statichost in/) do
        CLI.new(["init", "statichost"]).run
      end

      config_content_after = File.read(".beam_up.yml")
      assert_includes config_content_after, "# path: ./output"

      configuration = YAML.safe_load_file(".beam_up.yml")
      assert configuration.key?("bunny")
      assert configuration.key?("statichost")
    end

    def test_init_prefers_config_beam_up_yml_over_dot_beam_up_yml
      FileUtils.mkdir_p("config")
      File.write("config/beam_up.yml", YAML.dump({
        "provider" => "netlify",
        "netlify" => {"api_token" => "config_token", "project_id" => "config_site"}
      }))

      File.write(".beam_up.yml", YAML.dump({
        "provider" => "bunny",
        "bunny" => {"storage_zone_password" => "dot_token", "storage_zone_name" => "dot_zone", "region" => "dot_region"}
      }))

      assert_output(/Configured bunny in config\/beam_up\.yml/) do
        CLI.new(["init", "bunny"]).run
      end

      config_configuration = YAML.safe_load_file("config/beam_up.yml")
      assert config_configuration.key?("bunny")
      assert_equal "config_token", config_configuration["netlify"]["api_token"]

      dot_configuration = YAML.safe_load_file(".beam_up.yml")
      assert_equal "bunny", dot_configuration["provider"]
      refute dot_configuration.key?("netlify")
    end

    def test_init_does_not_duplicate_existing_provider
      File.write(".beam_up.yml", YAML.dump({
        "provider" => "netlify",
        "netlify" => {"api_token" => "existing_token", "project_id" => "existing_site"}
      }))

      assert_output(/Provider 'netlify' already configured/) do
        assert_raises(SystemExit) { CLI.new(["init", "netlify"]).run }
      end

      configuration = YAML.safe_load_file(".beam_up.yml")

      assert_equal "existing_token", configuration["netlify"]["api_token"]
    end

    def test_deploy_with_folder_path
      File.write(".beam_up.yml", YAML.dump({
        "provider" => "transporter",
        "transporter" => {"target_directory" => "./deployed"}
      }))

      FileUtils.mkdir_p("./output")
      File.write("./output/index.html", "<html></html>")

      cli = CLI.new(["./output"])

      output, _ = capture_io do
        cli.run
      end

      assert_includes output, "Transport complete"
      assert File.exist?("./deployed/index.html")
    end

    def test_deploy_without_folder_uses_config_path
      File.write(".beam_up.yml", YAML.dump({
        "provider" => "transporter",
        "path" => "./output",
        "transporter" => {"target_directory" => "./deployed"}
      }))

      FileUtils.mkdir_p("./output")
      File.write("./output/index.html", "<html></html>")

      cli = CLI.new([])

      output, _ = capture_io do
        cli.run
      end

      assert_includes output, "Transport complete"
      assert File.exist?("./deployed/index.html")
    end

    def test_deploy_with_provider_override
      File.write(".beam_up.yml", YAML.dump({
        "provider" => "netlify",
        "netlify" => {"api_token" => "test_token", "project_id" => "test_site"},
        "transporter" => {"target_directory" => "./beamed"}
      }))

      FileUtils.mkdir_p("./output")
      File.write("./output/index.html", "<html></html>")

      cli = CLI.new(["./output", "--provider", "transporter"])

      output, _ = capture_io do
        cli.run
      end

      assert_includes output, "Transport complete"
      assert File.exist?("./beamed/index.html")
    end

    def test_deploy_with_to_alias
      File.write(".beam_up.yml", YAML.dump({
        "provider" => "netlify",
        "netlify" => {"api_token" => "test_token", "project_id" => "test_site"},
        "transporter" => {"target_directory" => "./beamed"}
      }))

      FileUtils.mkdir_p("./output")
      File.write("./output/index.html", "<html></html>")

      cli = CLI.new(["./output", "--to", "transporter"])

      output, _ = capture_io do
        cli.run
      end

      assert_includes output, "Transport complete"
      assert File.exist?("./beamed/index.html")
    end

    def test_help_flag_shows_usage
      cli = CLI.new(["--help"])

      output, _ = capture_io do
        assert_raises(SystemExit) { cli.run }
      end

      assert_includes output, "Usage:"
      assert_includes output, "beam_up init [PROVIDER]"
      assert_includes output, "beam_up [FOLDER]"
      assert_includes output, "--provider"
      assert_includes output, "--to"
    end

    def test_help_short_flag
      cli = CLI.new(["-h"])

      output, _ = capture_io do
        assert_raises(SystemExit) { cli.run }
      end

      assert_includes output, "Usage:"
    end

    def test_no_config_shows_help
      cli = CLI.new([])

      output, _ = capture_io do
        assert_raises(SystemExit) { cli.run }
      end

      assert_includes output, "No .beam_up.yml found"
      assert_includes output, "beam_up init"
    end

    def test_unknown_command_treated_as_folder_path
      File.write(".beam_up.yml", YAML.dump({
        "provider" => "transporter",
        "path" => "./output",
        "transporter" => {"target_directory" => "./deployed"}
      }))

      FileUtils.mkdir_p("./unknown_command")
      File.write("./unknown_command/index.html", "<html></html>")

      cli = CLI.new(["unknown_command"])

      output, _ = capture_io do
        cli.run
      end

      assert_includes output, "Transport complete"
    end
  end
end
