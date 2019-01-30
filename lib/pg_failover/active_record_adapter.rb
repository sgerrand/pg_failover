# frozen_string_literal: true

module PgFailover
  class ActiveRecordAdapter
    def self.enable
      ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.set_callback(:checkout, :after) do
        # this seems to be the connection pool that internaly has the connection loaded for the current thread
        # methods like #execute and #reconnect! are against that connection
        connection = self

        PgFailover.connection_validator.call(
          throttle_by: connection.raw_connection,
          in_recovery: proc {
            result = connection.execute('select pg_is_in_recovery()').first

            %w[1 t true].include?(result['pg_is_in_recovery'].to_s)
          },
          reconnect: proc { connection.reconnect! }
        )
      end
    end
  end
end
