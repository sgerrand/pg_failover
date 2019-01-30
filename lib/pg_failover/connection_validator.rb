# frozen_string_literal: true

module PgFailover
  class ConnectionValidator
    def initialize(config)
      @logger = config.logger
      @max_retries = config.max_retries
      @throttle = Throttle.new(throttle_interval: config.throttle_interval)
      @config = config
    end

    attr_reader :logger, :max_retries, :throttle, :throttle_interval, :config

    def call(in_recovery:, reconnect:, throttle_by:)
      if config.throttle_enabled?
        throttle.on_stale(throttle_by) { check_and_reconnect(in_recovery, reconnect) }
      else
        check_and_reconnect(in_recovery, reconnect)
      end
    end

    private

    def check_if_db_is_in_recovery(in_recovery)
      in_recovery.call
    rescue StandardError => e
      logger.error("Got an error while trying to check pg_is_in_recovery, #{e.class}\n#{e.message}")
      true
    end

    def check_and_reconnect(in_recovery, reconnect)
      reconnect_attempts = 0

      while (connection_in_recovery = check_if_db_is_in_recovery(in_recovery))
        logger.info("The database is in recovery. Trying to reconnect. Attempt #{reconnect_attempts} from #{@max_retries}")
        reconnect.call

        reconnect_attempts += 1

        break if reconnect_attempts >= @max_retries

        sleep(rand(0..0.2))
      end

      !connection_in_recovery
    end
  end
end
