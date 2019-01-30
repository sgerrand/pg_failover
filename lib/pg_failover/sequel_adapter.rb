# frozen_string_literal: true

module PgFailover
  module SequelAdapter
    class << self
      def register_extension
        ::Sequel::Database.register_extension(:postgres_failover_validator) do |db|
          db.pool.extend(PgFailover::SequelAdapter::ConnectionValidator)
        end
      end

      def enable(databases = Sequel::DATABASES)
        register_extension

        databases.each do |db|
          db.extension :postgres_failover_validator if db.adapter_scheme == :postgres
        end
      end
    end

    module ConnectionValidator
      def acquire(*a)
        connection = super

        PgFailover.connection_validator.call(
          throttle_by: connection,
          in_recovery: proc {
            result = connection.execute('select pg_is_in_recovery()') { |r| r.to_a }.first
            %w[1 t true].include?(result['pg_is_in_recovery'].to_s)
          },
          reconnect: proc {
            # This disconnect is copy pasted from the
            # https://github.com/jeremyevans/sequel/blob/5.15.0/lib/sequel/extensions/connection_validator.rb#L103-L109
            #
            if pool_type == :sharded_threaded
              sync{allocated(a.last).delete(Thread.current)}
            else
              sync{@allocated.delete(Thread.current)}
            end

            disconnect_connection(connection)

            connection = super
          }
        )

        connection
      end
    end
  end
end
