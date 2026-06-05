# frozen_string_literal: true

module BeamUp
  class Progress
    def initialize
      @mutex = Thread::Mutex.new
      @current = 0
      @total = nil
      @type = nil
      @spinner_index = 0
    end
    attr_reader :total, :current, :type

    def start(type:, total:)
      @mutex.synchronize do
        @type = type
        @total = total
        @current = 0
        @spinner_index = 0

        render
      end
    end

    def tick(bytes: nil)
      @mutex.synchronize do
        @current += (@type == :bytes) ? bytes.to_i : 1

        render
      end
    end

    def finish
      @mutex.synchronize do
        return if @total.nil?

        stop_render

        @total = nil
        @current = nil
        @type = nil
      end
    end

    private

    SPINNERS = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇]

    def render
      return unless tty?

      spinner = SPINNERS[@spinner_index % SPINNERS.length]
      @spinner_index += 1

      line = if @type == :bytes
        "#{spinner} #{formatted(@current)} of #{formatted(@total)}"
      else
        "#{spinner} #{@current} of #{@total}"
      end

      $stdout.write("\r#{line}")

      $stdout.flush
    end

    def stop_render
      $stdout.write("\r#{" " * 80}\r")

      $stdout.flush
    end

    def tty? = $stdout.tty?

    def formatted(bytes)
      return format("%.1fGB", bytes.to_f / 1_073_741_824) if bytes >= 1_073_741_824
      return format("%.1fMB", bytes.to_f / 1_048_576) if bytes >= 1_048_576
      return format("%.1fKB", bytes.to_f / 1024) if bytes >= 1024

      "#{bytes}B"
    end
  end
end
