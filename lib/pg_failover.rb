# frozen_string_literal: true

module PgFailover
  autoload :ActiveRecordAdapter, 'pg_failover/active_record_adapter'
  autoload :Config, 'pg_failover/config'
  autoload :ConnectionValidator, 'pg_failover/connection_validator'
  autoload :SequelAdapter, 'pg_failover/sequel_adapter'
  autoload :Throttle, 'pg_failover/throttle'

  class << self
    def configure
      yield configuration if block_given?

      if configuration.enabled?
        if configuration.throttle_enabled?
          configuration.logger.info("Enabled PgFailover policy (one check per #{configuration.throttle_interval} seconds per connection on checkout)")
        else
          configuration.logger.info('Enabled PgFailover policy (one check for every checkout from the connection pool)')
        end

        SequelAdapter.enable if defined?(::Sequel)
        ActiveRecordAdapter.enable if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)

      else
        configuration.logger.warn 'Disabled PgFailover policy'
      end
    end

    def connection_validator
      @connection_validator ||= ConnectionValidator.new(configuration)
    end

    def configuration
      @configuration ||= Config.new
    end
  end
end
