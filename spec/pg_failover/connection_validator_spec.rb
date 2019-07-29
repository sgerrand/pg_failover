require 'spec_helper'
require 'pg_failover'

RSpec.describe PgFailover::ConnectionValidator do
  let(:null_logger) { Logger.new('/dev/null') }

  def config(options = {})
    c = { logger: null_logger }.merge(options)
    PgFailover::Config.new(c[:enabled], c[:logger], c[:max_retries], c[:throttle_interval])
  end

  describe '#call' do
    context 'when the db is not in recovery' do
      it 'will not try to reconnect' do
        validator = described_class.new(config)

        reconnected = false

        validator.call(
          throttle_by: 'something',
          in_recovery: proc { false },
          reconnect: proc { reconnected = true }
        )

        expect(reconnected).to eq(false)
      end

      it 'will not try to check again if there is a throttle_interval and it checked recently' do
        validator = described_class.new(config(throttle_interval: 10.0))

        calls_to_in_recovery = 0
        reconnected = false

        3.times do
          validator.call(
            throttle_by: 'something',
            in_recovery: proc do
              calls_to_in_recovery += 1
              false
            end,
            reconnect: proc { reconnected = true }
          )
        end

        expect(calls_to_in_recovery).to eq(1)
        expect(reconnected).to eq(false)
      end
    end

    context 'when the db is in recovery' do
      it 'will try to reconnect' do
        validator = described_class.new(config)

        reconnected = false

        validator.call(
          throttle_by: 'something',
          in_recovery: proc { true },
          reconnect: proc { reconnected = true }
        )

        expect(reconnected).to eq(true)
      end

      it 'will try to reconnect even if there is a throttle_interval' do
        validator = described_class.new(config(throttle_interval: 10.0))

        calls_to_in_recovery = 0
        calls_to_reconnect = 0

        3.times do
          validator.call(
            throttle_by: 'something',
            in_recovery: proc do
              calls_to_in_recovery += 1
              true
            end,
            reconnect: proc { calls_to_reconnect += 1 }
          )
        end

        expect(calls_to_in_recovery).to eq(3)
        expect(calls_to_reconnect).to eq(3)
      end
    end

    context 'when the db does not recover immediately' do
      it 'will try to reconnect up to a limit of max_retries' do
        validator = described_class.new(config(max_retries: 5))

        calls_to_in_recovery = 0
        calls_to_reconnect = 0

        validator.call(
          throttle_by: 'something',
          in_recovery: proc do
            calls_to_in_recovery += 1
            true
          end,
          reconnect: proc { calls_to_reconnect += 1 }
        )

        expect(calls_to_in_recovery).to eq(5)
        expect(calls_to_reconnect).to eq(5)
      end
    end
  end
end
