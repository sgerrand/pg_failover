# frozen_string_literal: true

module PgFailover
  class Throttle
    def initialize(throttle_interval: nil)
      @last_good_at = {}
      @throttle_interval = throttle_interval || 0.0
    end

    attr_reader :throttle_interval

    def size
      @last_good_at.count
    end

    def on_stale(connection)
      return if should_throttle?(connection)

      clear_stale_throttle_times

      valid = yield

      @last_good_at[connection] = Time.now.to_f if valid
    end

    def should_throttle?(connection)
      return if @last_good_at[connection].nil?

      connection_check_age = (Time.now.to_f - @last_good_at[connection])
      connection_check_age < throttle_interval
    end

    def known?(connection)
      @last_good_at[connection]
    end

    private

    def clear_stale_throttle_times
      stale_after = Time.now.to_f - throttle_interval * 3

      @last_good_at.delete_if { |_k, v| stale_after > v }
    end
  end
end
