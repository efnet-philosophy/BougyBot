require 'pathname'
require 'logger'
$LOAD_PATH.unshift File.join(ENV['HOME'], 'g/cleverbot/lib')

# Allows for pathnames to be easily added to
class Pathname
  def /(other)
    join(other.to_s)
  end
end

# simple irc bot
# This sets all the globals and creates our main namespace
module BougyBot
  LIBROOT = Pathname(__FILE__).dirname.expand_path
  ROOT = LIBROOT / '..'
  MIGRATION_ROOT = ROOT / :migrations
  MODEL_ROOT = ROOT / :model
  SPEC_HELPER_PATH = ROOT / :spec
  autoload :VERSION, (LIBROOT / 'bougy_bot/version').to_s
  # Helper method to load models
  # @model String The model you wish to load
  def self.M(model)
    require BougyBot::MODEL_ROOT.join(model).to_s
  end

  # Helper method to load files from ROOT
  # @file String The file you wish to load
  def self.R(file)
    require BougyBot::ROOT.join(file).to_s
  end

  # Helper method to load files from lib/yrb
  # @file String The file you wish to load
  def self.L(file)
    require (BougyBot::LIBROOT / :bougy_bot).join(file).to_s
  end

  def self.t(things)
    tto = options.talk_to
    things = Array(things)
    things.each do |thing|
      tto.include?(thing) ? tto.delete(thing) : (tto << thing)
    end
    tto
  end

  def self.Run(*args)
    require 'open3'
    Open3.popen3(*args) do |sin, sout, serr|
      o = Thread.new do
        sout.each_line { |l| puts l.chomp }
      end
      e = Thread.new do
        serr.each_line { |l| $stderr.puts l.chomp }
      end
      sin.close
      o.join
      e.join
    end
  end

  def self.phil(bot)
    bot.channels.detect { |d| d.name == '#philosophy' }
  end

  def self.cur_users(bot)
    bot.config.authentication.logged_in
  end
end
BougyBot::R 'lib/core_ext/hash'
BougyBot::R 'options'
BougyBot::Log = Logger.new(BougyBot.options.logfile, 10, 10_240_000) unless BougyBot.const_defined?('Log')
BougyBot::Log.level = BougyBot.options.log_level
