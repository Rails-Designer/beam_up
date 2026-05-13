# frozen_string_literal: true

module BeamUp
  class Result
    attr_reader :deploy_id, :error, :provider

    def initialize(provider:, deploy_id: nil, url: nil, error: nil)
      @provider = provider
      @deploy_id = deploy_id
      @url = url
      @error = error
    end

    def success? = @error.nil?

    def failure? = !success?

    def message
      if success?
        "Successfully deployed to #{@provider}#{" at #{@url}" if @url}"
      else
        "Deployment to #{@provider} failed: #{@error}"
      end
    end
  end
end
