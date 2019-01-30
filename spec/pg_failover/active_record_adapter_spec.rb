require 'spec_helper'
require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'
require 'pg_failover'

RSpec.describe PgFailover::ActiveRecordAdapter do
  let(:null_logger) { Logger.new('/dev/null') }

  def config(options = {})
    c = { logger: null_logger }.merge(options)
    PgFailover::Config.new(c[:enabled], c[:logger], c[:max_retries], c[:throttle_interval])
  end

  let(:connection_validator) { PgFailover::ConnectionValidator.new(config) }

  before do
    allow(PgFailover).to receive(:connection_validator).and_return(connection_validator)
  end

  describe '#enable' do
    it 'hooks sets a callback on a connection checkout' do
      expect(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:set_callback).with(:checkout, :after)

      described_class.enable
    end

    it 'passes a in_recovery proc that checks pg_is_in_recovery to the connection_validator' do
      callback = nil

      expect(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:set_callback).with(:checkout, :after) { |*_args, &block| callback = block }

      described_class.enable

      in_recovery_proc = nil

      expect(connection_validator).to receive(:call) { |throttle_by:, in_recovery:, reconnect:| in_recovery_proc = in_recovery }

      connection_pool = double('PostgreSQLAdapter', raw_connection: '123')

      connection_pool.instance_eval(&callback)

      expect(connection_pool).to receive(:execute).with('select pg_is_in_recovery()').and_return([{ 'pg_is_in_recovery' => 't' }])

      expect(in_recovery_proc.call).to eq(true)
    end

    it 'passes a reconnect proc that reconnects the current connection' do
      callback = nil

      expect(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:set_callback).with(:checkout, :after) { |*_args, &block| callback = block }

      described_class.enable

      reconnect_proc = nil

      expect(connection_validator).to receive(:call) { |throttle_by:, in_recovery:, reconnect:| reconnect_proc = reconnect }

      connection_pool = double('PostgreSQLAdapter', raw_connection: '123')

      connection_pool.instance_eval(&callback)

      expect(connection_pool).to receive(:reconnect!)

      reconnect_proc.call
    end
  end
end
