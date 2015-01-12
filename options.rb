require "innate"

module BougyBot
  include Innate::Optioned

  options.dsl do
    o "Database", :db, ENV["BougyBot_DB"] || "postgres://bougybot:bougybot@localhost/bougybot"

    o "Logfile", :logfile, ENV["BougyBot_LOG"] || $stdout

    o "Log Level", :log_level, ENV["BougyBot_LogLevel"] || Logger::INFO

    o "Debug Output", :debug, ENV['BougyBot_Debug']

    o "Debugger Hooks (pry)", :debugger, ENV['BougyBot_Debugger']

    o "No Long Sleep", :nodoze, ENV['BougyBot_Nodoze']

    o "Sleep", :sleeps, ([10] * 100) + ([30] * 50) + ([60] * 25) + ([100] * 10) + ([500] * 5) + [1000]
    
    o 'Always Talk To', :talk_to, ['howto', '(?-i:[A-Z\ ]{10,})']

    o 'Nick', :nick, 'pangaea'
  end

end

