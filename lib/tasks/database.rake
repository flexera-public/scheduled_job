desc "initialises a database connection"
task :dbconnect do
  Db::Connect.init
end
