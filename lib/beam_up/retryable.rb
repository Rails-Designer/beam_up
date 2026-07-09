# frozen_string_literal: true

require "net/http"

module BeamUp
  module Retryable
    NETWORK_ERRORS = [
      Net::WriteTimeout,
      Net::ReadTimeout,
      Errno::ECONNRESET,
      Errno::EPIPE,
      EOFError
    ]

    private

    def retryable_request(uri, maximum_retry_count: 3, open_timeout: 30, write_timeout: 300, read_timeout: 300)
      maximum_attempt_count = maximum_retry_count + 1

      maximum_attempt_count.times do |attempt|
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.open_timeout = open_timeout
          http.write_timeout = write_timeout
          http.read_timeout = read_timeout

          http.request(yield)
        end

        return response
      rescue *NETWORK_ERRORS
        raise if attempt == maximum_retry_count

        sleep(2**attempt)
      end
    end
  end
end
