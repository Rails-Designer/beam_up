# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "beam_up"

ENV["TTY_TEST"] = "true"

require "minitest/autorun"
