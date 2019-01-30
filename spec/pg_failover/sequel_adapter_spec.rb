require 'spec_helper'
begin
  require 'sequel'
rescue LoadError => _
end
require 'pg_failover'

RSpec.describe PgFailover::SequelAdapter do
  before do
    skip 'No sequel gem' unless defined?(::Sequel)
  end

  describe '.register_extension' do
    it 'registers the postgres_failover_validator extension' do
      described_class.register_extension

      expect(::Sequel::Database::EXTENSIONS[:postgres_failover_validator]).to be_present
    end
  end

  describe '.enable' do
    it 'registers the :postgres_failover_validator extension' do
      described_class.enable

      expect(::Sequel::Database::EXTENSIONS[:postgres_failover_validator]).to be_present
    end

    it 'will enable the extensions for all sequel databases' do
      database = double('Sequel Database', adapter_scheme: :postgres)

      stub_const('::Sequel::DATABASES', [database])

      expect(database).to receive(:extension).with(:postgres_failover_validator)

      described_class.enable
    end

    it 'will not enable the extension for non postgres connections' do
      database = double('Sequel Database', adapter_scheme: :mysql)

      stub_const('::Sequel::DATABASES', [database])

      expect(database).not_to receive(:extension).with(:postgres_failover_validator)

      described_class.enable
    end
  end
end
