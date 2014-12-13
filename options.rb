require "innate"

module BougyBot
  include Innate::Optioned

  options.dsl do
    o "Database", :db, ENV["BougyBot_DB"] || "sqlite://#{Pathname(__FILE__).dirname.expand_path.join('db/bougy_bot.db')}"

    o "Logfile", :logfile, ENV["BougyBot_LOG"] || $stdout

    o "Log Level", :log_level, ENV["BougyBot_LogLevel"] || Logger::INFO
  end

end

