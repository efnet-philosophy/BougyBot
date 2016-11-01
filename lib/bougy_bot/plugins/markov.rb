require 'marky_markov'
require 'cinch'

module BougyBot
	module Plugins
		class Markov
		  include Cinch::Plugin

		  set plugin_name: "Markov"

		  listen_to :channel, method: :execute
		  timer 60, method: :save_dict

		  def initialize(*args)
		  	super(*args)
		  	@markov = MarkyMarkov::Dictionary.new('markov_dictionary')
		  end

		  def execute(m)
		  	if Regexp.new("^" + Regexp.escape(m.bot.nick + ":" )) =~ m.message
          Timer(rand(3..10), shots: 1) { m.reply("#{m.user.nick}: #{@markov.generate_n_sentences(rand(1..3))}") }
		  	elsif m.message.match /(https?:\/\/[^\s]+)/ # return on urls
		  		return
		  	else
		  		@markov.parse_string(m.message)
		  	end
		  end

		  def save_dict
		  	@markov.save_dictionary!
		  end

		end
	end
end
