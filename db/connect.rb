require 'active_record'

module Db
  class Connect
    def self.init
      ActiveRecord::Base.establish_connection(
        :adapter => "sqlite3",
        :dbfile  => ":memory:",
        :database => "scheduled_job"
      )

      require_relative 'schema'
    end
  end
end
