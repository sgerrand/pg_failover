# frozen_string_literal: true

require 'logger'

module PgFailover
  Config = Struct.new(:enabled, :logger, :max_retries, :throttle_interval) do
    def logger
      self[:logger] ||= Logger.new($stdout)
    end

    def throttle_interval
      self[:throttle_interval] ||= (ENV['POSTGRES_FAILOVER_THROTTLE_INTERVAL'] || 10.0).to_f
    end

    def throttle_enabled?
      !throttle_interval.zero?
    end

    def max_retries
      self[:max_retries] ||= (ENV['POSTGRES_FAILOVER_MAX_RETRIES'] || 1).to_i
    end

    def enabled
      self[:enabled] ||= %w[1 t true].include?(ENV['POSTGRES_FAILOVER_ENABLED'])
    end

    def enabled?
      !!enabled
    end
  end
end
