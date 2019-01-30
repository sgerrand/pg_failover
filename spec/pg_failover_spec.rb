require 'spec_helper'
require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'
begin
  require 'sequel'
rescue LoadError => _
end
require 'pg_failover'

RSpec.describe PgFailover do
  let(:null_logger) { Logger.new('/dev/null') }
  let(:db)          { double('Database Double') }
  let(:pool)        { double('Connection Pool Double') }

  before do
    allow(PgFailover::ActiveRecordAdapter).to receive(:enable)
    allow(PgFailover::SequelAdapter).to receive(:enable)
  end

  describe '.configure' do
    it 'by default it is not enabled' do
      described_class.configure { |config| config.logger = null_logger }

      expect(described_class.configuration.enabled?).to eq(false)
    end

    context 'active_record' do
      it 'will set the failover policy for active record with the provided config' do
        expect(PgFailover::ActiveRecordAdapter).not_to receive(:enable)

        described_class.configure do |config|
          config.enabled = false
          config.throttle_interval = 3.0
          config.max_retries = 2
          config.logger = null_logger
        end

        aggregate_failures do
          expect(described_class.configuration.throttle_interval).to eq(3.0)
          expect(described_class.configuration.max_retries).to eq(2)
          expect(described_class.configuration.logger).to eq(null_logger)
          expect(described_class.configuration.enabled?).to eq(false)
        end
      end

      it 'will set the failover policy for active record with the provided config' do
        expect(PgFailover::ActiveRecordAdapter).to receive(:enable)

        described_class.configure do |config|
          config.enabled = true
          config.throttle_interval = 3.0
          config.max_retries = 2
          config.logger = null_logger
        end

        aggregate_failures do
          expect(described_class.configuration.throttle_interval).to eq(3.0)
          expect(described_class.configuration.max_retries).to eq(2)
          expect(described_class.configuration.logger).to eq(null_logger)
          expect(described_class.configuration.enabled?).to eq(true)
        end
      end
    end

    context 'sequel' do
      it 'does not enable the failover policy for sequel if enabled is false in the config' do
        skip 'No sequel gem' unless defined?(::Sequel)

        expect(PgFailover::SequelAdapter).not_to receive(:enable)

        described_class.configure do |config|
          config.enabled = false
          config.throttle_interval = 3.0
          config.max_retries = 2
          config.logger = null_logger
        end

        aggregate_failures do
          expect(described_class.configuration.throttle_interval).to eq(3.0)
          expect(described_class.configuration.max_retries).to eq(2)
          expect(described_class.configuration.logger).to eq(null_logger)
          expect(described_class.configuration.enabled?).to eq(false)
        end
      end

      it 'enables the failover policy for sequel if enabled is true in the config' do
        skip 'No sequel gem' unless defined?(::Sequel)

        expect(PgFailover::SequelAdapter).to receive(:enable)

        described_class.configure do |config|
          config.enabled = true
          config.throttle_interval = 3.0
          config.max_retries = 2
          config.logger = null_logger
        end

        aggregate_failures do
          expect(described_class.configuration.throttle_interval).to eq(3.0)
          expect(described_class.configuration.max_retries).to eq(2)
          expect(described_class.configuration.logger).to eq(null_logger)
          expect(described_class.configuration.enabled?).to eq(true)
        end
      end
    end
  end
end
