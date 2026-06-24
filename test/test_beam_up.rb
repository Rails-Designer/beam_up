# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class BeamUpTest < Minitest::Test
  def setup
    @original_directory = Dir.pwd
    @temporary_directory = Dir.mktmpdir

    Dir.chdir(@temporary_directory)

    BeamUp::Core.instance_variable_set(:@configuration, nil)
    BeamUp::Core.instance_variable_set(:@config_file, nil)
  end

  def teardown
    Dir.chdir(@original_directory)
    FileUtils.rm_rf(@temporary_directory)

    BeamUp::Core.instance_variable_set(:@configuration, nil)
    BeamUp::Core.instance_variable_set(:@config_file, nil)
  end

  def test_version_constant_exists
    refute_nil BeamUp::VERSION
  end

  def test_raises_when_no_config_file
    error = assert_raises(BeamUp::ConfigurationError) do
      BeamUp.configuration
    end

    assert_includes error.message, "beam_up init"
  end

  def test_loads_config_from_file
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "netlify",
      "path" => "./output",
      "netlify" => {"api_token" => "test_token", "project_id" => "test_site"}
    }))

    config = BeamUp.configuration

    assert_equal "netlify", config.provider
    assert_equal "./output", config.path
    assert_equal "test_token", config.netlify.api_token
  end

  def test_loads_timeout_from_config
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "netlify",
      "timeout" => 600,
      "netlify" => {"api_token" => "test_token"}
    }))

    config = BeamUp.configuration

    assert_equal 600, config.timeout
  end

  def test_uses_default_timeout_when_not_specified
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "netlify",
      "netlify" => {"api_token" => "test_token"}
    }))

    config = BeamUp.configuration

    assert_equal BeamUp::Configuration::DEFAULT_TIMEOUT, config.timeout
  end

  def test_prefers_config_directory_over_root_config
    File.write(".beam_up.yml", YAML.dump({"provider" => "netlify", "netlify" => {"api_token" => "token1"}}))
    FileUtils.mkdir_p("config")
    File.write("config/beam_up.yml", YAML.dump({"provider" => "bunny", "bunny" => {"storage_zone_password" => "key1"}}))

    assert_equal "bunny", BeamUp.configuration.provider
  end

  def test_prefers_yml_over_yml_erb_when_both_exist
    File.write(".beam_up.yml", YAML.dump({"provider" => "netlify", "netlify" => {"api_token" => "yml_token"}}))
    File.write(".beam_up.yml.erb", "provider: seal_static\nseal_static:\n  api_key: erb_key\n")

    config = BeamUp.configuration

    assert_equal "netlify", config.provider
    assert_equal "yml_token", config.netlify.api_token
  end

  def test_uses_yml_erb_when_yml_does_not_exist
    File.write(".beam_up.yml.erb", "provider: seal_static\nseal_static:\n  api_key: <%= 'erb' + '_key' %>\n")

    config = BeamUp.configuration

    assert_equal "seal_static", config.provider
    assert_equal "erb_key", config.seal_static.api_key
  end

  def test_configure_yields_config
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "netlify",
      "netlify" => {"api_token" => "test_token"}
    }))

    BeamUp.configure { |c| c.provider = "bunny" }

    assert_equal "bunny", BeamUp.configuration.provider
  end

  def test_deploy_requires_path
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "netlify",
      "netlify" => {"api_token" => "test_token"}
    }))

    error = assert_raises(BeamUp::ConfigurationError) do
      BeamUp.deploy!
    end

    assert_equal "No path specified", error.message
  end

  def test_deploy_accepts_provider_override
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "transporter",
      "path" => "./output",
      "transporter" => {"target_directory" => "./beamed"}
    }))

    FileUtils.mkdir_p("./output")
    File.write("./output/index.html", "<html></html>")

    beamed = BeamUp.deploy!("./output", provider: "transporter")

    assert beamed.success?
    assert_equal "Transporter", beamed.provider
    assert File.exist?("./beamed/index.html")
  end

  def test_deploy_accepts_to_alias
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "netlify",
      "netlify" => {"api_token" => "test_token", "project_id" => "test_site"},
      "transporter" => {"target_directory" => "./beamed"}
    }))

    FileUtils.mkdir_p("./output")
    File.write("./output/index.html", "<html></html>")

    beamed = BeamUp.deploy!("./output", to: "transporter")

    assert beamed.success?
    assert_equal "Transporter", beamed.provider
    assert File.exist?("./beamed/index.html")
  end

  def test_deploy_accepts_symbol_provider
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "netlify",
      "netlify" => {"api_token" => "test_token", "project_id" => "test_site"},
      "transporter" => {"target_directory" => "./beamed"}
    }))

    FileUtils.mkdir_p("./output")
    File.write("./output/index.html", "<html></html>")

    beamed = BeamUp.deploy!("./output", provider: :transporter)

    assert beamed.success?
    assert_equal "Transporter", beamed.provider
    assert File.exist?("./beamed/index.html")
  end

  def test_deploy_executes_before_actions
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "transporter",
      "path" => "./output",
      "before_actions" => ["echo 'Energizing pre-flight systems…'", "echo 'Pattern buffers aligned.'"],
      "transporter" => {"target_directory" => "./beamed"}
    }))

    FileUtils.mkdir_p("./output")
    File.write("./output/index.html", "<html></html>")

    beamed = BeamUp.deploy!("./output")

    assert beamed.success?
  end

  def test_deploy_executes_after_actions
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "transporter",
      "path" => "./output",
      "after_actions" => ["echo 'Transport complete.'", "echo 'Mission accomplished, Captain.'"],
      "transporter" => {"target_directory" => "./beamed"}
    }))

    FileUtils.mkdir_p("./output")
    File.write("./output/index.html", "<html></html>")

    beamed = BeamUp.deploy!("./output")

    assert beamed.success?
  end

  def test_deploy_stops_if_before_action_fails
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "transporter",
      "path" => "./output",
      "before_actions" => ["false"],
      "transporter" => {"target_directory" => "./beamed"}
    }))

    FileUtils.mkdir_p("./output")
    File.write("./output/index.html", "<html></html>")

    error = assert_raises(BeamUp::ConfigurationError) do
      BeamUp.deploy!("./output")
    end

    assert_includes error.message, "Before action failed"
    refute File.exist?("./beamed/index.html")
  end

  def test_configuration_loads_from_custom_config_file
    custom_config_path = File.join(@temporary_directory, "custom.yml")
    File.write(custom_config_path, YAML.dump({
      "provider" => "netlify",
      "path" => "./output",
      "netlify" => {"api_token" => "custom_token", "project_id" => "custom_site"}
    }))

    config = BeamUp.configuration(config_file: custom_config_path)

    assert_equal "netlify", config.provider
    assert_equal "custom_token", config.netlify.api_token
  end

  def test_configuration_ignores_default_files_when_config_file_specified
    File.write(".beam_up.yml", YAML.dump({
      "provider" => "netlify",
      "netlify" => {"api_token" => "default_token"}
    }))

    custom_config_path = File.join(@temporary_directory, "custom.yml")
    File.write(custom_config_path, YAML.dump({
      "provider" => "bunny",
      "bunny" => {"storage_zone_password" => "custom_password"}
    }))

    config = BeamUp.configuration(config_file: custom_config_path)

    assert_equal "bunny", config.provider
  end

  def test_configure_allows_setting_config_file_path
    custom_config_path = File.join(@temporary_directory, "custom.yml")
    File.write(custom_config_path, YAML.dump({
      "provider" => "netlify",
      "netlify" => {"api_token" => "configured_token"}
    }))

    BeamUp.config_file = custom_config_path

    config = BeamUp.configuration

    assert_equal "netlify", config.provider
    assert_equal "configured_token", config.netlify.api_token
  end

  def test_deploy_with_custom_config_file
    custom_config_path = File.join(@temporary_directory, "deploy_config.yml")
    File.write(custom_config_path, YAML.dump({
      "provider" => "transporter",
      "path" => "./output",
      "transporter" => {"target_directory" => "./beamed"}
    }))

    FileUtils.mkdir_p("./output")
    File.write("./output/index.html", "<html></html>")

    beamed = BeamUp.deploy!("./output", config_file: custom_config_path)

    assert beamed.success?
    assert_equal "Transporter", beamed.provider
    assert File.exist?("./beamed/index.html")
  end

  def test_yaml_load_parses_yml_file
    File.write("config.yml", YAML.dump({"key" => "value"}))

    result = BeamUp::Core.yaml_load("config.yml")

    assert_equal({"key" => "value"}, result)
  end

  def test_yaml_load_processes_erb_in_yml_erb_file
    File.write("config.yml.erb", "key: <%= 'hello' + '_world' %>")

    result = BeamUp::Core.yaml_load("config.yml.erb")

    assert_equal({"key" => "hello_world"}, result)
  end

  def test_yaml_load_parses_yml_erb_file_without_erb_tags
    File.write("config.yml.erb", YAML.dump({"key" => "value"}))

    result = BeamUp::Core.yaml_load("config.yml.erb")

    assert_equal({"key" => "value"}, result)
  end

  def test_yaml_load_does_not_process_erb_in_yml_file
    File.write("config.yml", "key: <%= 'hello' %>")

    result = BeamUp::Core.yaml_load("config.yml")

    assert_equal({"key" => "<%= 'hello' %>"}, result)
  end
end
