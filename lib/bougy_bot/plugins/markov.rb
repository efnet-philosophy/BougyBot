require 'marky_markov'
require 'cinch'
require 'cinch/cooldown'

module BougyBot
	module Plugins
		class Markov
		  include Cinch::Plugin
      enforce_cooldown

		  set plugin_name: "Markov"

		  listen_to :channel, method: :execute
		  timer 60, method: :save_dict

		  def initialize(*args)
		  	super(*args)
		  	@markov = MarkyMarkov::Dictionary.new('markov_dictionary')
		  end

		  def execute(m)
        return unless m.message =~ Regexp.new(Regexp.escape(m.bot.nick)) || %w(strewth wave).include?(m.user.nick) || m.message =~ /\b(strewth|wave)\b/
        return if rand(1..10) < 8
        imer(rand(3..10), shots: 1) { m.reply("#{m.user.nick}: #{@markov.generate_n_sentences(rand(1..3))}") }
		  	return unless m.message.match /(https?:\/\/[^\s]+)/ # return on urls
		  	@markov.parse_string(m.message)
		  end

		  def save_dict
		  	@markov.save_dictionary!
		  end

		end
	end
end
