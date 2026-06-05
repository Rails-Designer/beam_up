# frozen_string_literal: true

require "test_helper"

module BeamUp
  class ProgressTest < Minitest::Test
    def test_start_sets_total_and_type
      progress = BeamUp::Progress.new

      progress.start(type: :files, total: 47)

      assert_equal 47, progress.total
      assert_equal :files, progress.type
    end

    def test_start_with_bytes_type
      progress = BeamUp::Progress.new

      progress.start(type: :bytes, total: 1_048_576)

      assert_equal 1_048_576, progress.total
      assert_equal :bytes, progress.type
    end

    def test_tick_increments_current_for_files
      progress = BeamUp::Progress.new

      progress.start(type: :files, total: 10)
      progress.tick

      assert_equal 1, progress.current
    end

    def test_tick_adds_bytes_for_bytes_type
      progress = BeamUp::Progress.new

      progress.start(type: :bytes, total: 1_000_000)
      progress.tick(bytes: 1024)

      assert_equal 1024, progress.current
    end

    def test_finish_resets_state
      progress = BeamUp::Progress.new
      progress.start(type: :files, total: 10)

      progress.tick
      progress.finish

      assert_nil progress.total
      assert_nil progress.current
    end
  end
end
