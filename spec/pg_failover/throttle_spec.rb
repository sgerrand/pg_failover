require 'spec_helper'
require 'pg_failover'

RSpec.describe PgFailover::Throttle do
  describe '#on_stale' do
    let(:connection)   { double('Connection') }
    let(:t0)          { Time.now }
    let(:throttle)    { described_class.new(throttle_interval: 1.0) }

    it 'runs the block if there is no throttle for the passed argument' do
      ack = false

      throttle.on_stale(connection) { ack = true }

      expect(ack).to be true
    end

    it 'does not run the block if the pass argument is with throttle is active' do
      throttle.on_stale(connection) { true }

      ack = false

      throttle.on_stale(connection) { ack = true }

      expect(ack).to be false
    end

    it 'ignores the throttle if the block is false -> the connection is bad' do
      throttle.on_stale(connection) { false }

      ack = false

      throttle.on_stale(connection) { ack = true }

      expect(ack).to be true
    end

    it 'run the block if throttle has expired' do
      throttle.on_stale(connection) { true }

      ack = false

      allow(Time).to receive(:now).and_return(t0 + 1.1)

      throttle.on_stale(connection) { ack = true }

      expect(ack).to be true
    end

    it 'clears out stale connections' do
      throttle.on_stale(connection) { true }

      10.times { throttle.on_stale(double) { true } }

      expect(throttle.size).to eq(11)

      allow(Time).to receive(:now).and_return(t0 + 3.1)

      throttle.on_stale(connection) { true }

      expect(throttle.size).to eq(1)
    end
  end
end
