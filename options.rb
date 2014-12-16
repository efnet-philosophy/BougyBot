require "innate"

module BougyBot
  include Innate::Optioned

  options.dsl do
    o "Database", :db, ENV["BougyBot_DB"] || "postgres://bougybot:bougybot@localhost/bougybot"

    o "Logfile", :logfile, ENV["BougyBot_LOG"] || $stdout

    o "Log Level", :log_level, ENV["BougyBot_LogLevel"] || Logger::INFO

    o "Debug Output", :debug, ENV['BougyBot_Debug']

    o "Debugger Hooks (pry)", :debugger, ENV['BougyBot_Debugger']
  end

end

