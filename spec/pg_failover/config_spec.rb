# frozen_string_literal: true

require 'spec_helper'
require 'pg_failover'

RSpec.describe PgFailover::Config do
  describe '#logger' do
    it 'is some kind of Logger' do
      expect(described_class.new.logger).to be_a(Logger)
    end
  end

  describe '#throttle_interval' do
    it 'is 10.0 by default' do
      expect(described_class.new.throttle_interval).to eq(10.0)
    end

    it 'could be configured through POSTGRES_FAILOVER_THROTTLE_INTERVAL' do
      with_env('POSTGRES_FAILOVER_THROTTLE_INTERVAL' => '3.5') do
        expect(described_class.new.throttle_interval).to eq(3.5)
      end
    end
  end

  describe '#throttle_enabled?' do
    it 'is enabled if there is a throttle_interval' do
      config = described_class.new
      config.throttle_interval = 10.0
      expect(config.throttle_enabled?).to eq(true)
    end

    it 'is false if the throttle_interval is 0' do
      config = described_class.new

      config.throttle_interval = 0
      expect(config.throttle_enabled?).to eq(false)

      config.throttle_interval = 0.0
      expect(config.throttle_enabled?).to eq(false)
    end
  end

  describe '#max_retries' do
    it 'is 1 by default' do
      expect(described_class.new.max_retries).to eq(1)
    end

    it 'could be configured through POSTGRES_FAILOVER_MAX_RETRIES' do
      with_env('POSTGRES_FAILOVER_MAX_RETRIES' => '3') do
        expect(described_class.new.max_retries).to eq(3)
      end
    end
  end

  describe '#enabled?' do
    it 'is false by default' do
      expect(described_class.new.enabled?).to eq(false)
    end

    it 'could be configured through POSTGRES_FAILOVER_ENABLED' do
      with_env('POSTGRES_FAILOVER_ENABLED' => '1') do
        expect(described_class.new.enabled?).to eq(true)
      end

      with_env('POSTGRES_FAILOVER_ENABLED' => 't') do
        expect(described_class.new.enabled?).to eq(true)
      end

      with_env('POSTGRES_FAILOVER_ENABLED' => 'true') do
        expect(described_class.new.enabled?).to eq(true)
      end
    end
  end
end
