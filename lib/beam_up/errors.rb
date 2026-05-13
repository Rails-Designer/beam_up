module BeamUp
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class DeploymentError < Error; end
end
