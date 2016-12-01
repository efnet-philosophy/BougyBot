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
        if m.message =~ /^useful[:,] /
          spew m
        elsif m.message =~ Regexp.new(Regexp.escape(m.bot.nick)) || %w(strewth wave).include?(m.user.nick) || m.message =~ /\b(strewth|wave)\b/
          return if rand < 0.9
          spew m
        elsif m.message.each_char.select { |t| t =~ /[A-Z]/ }.count > 10
          spew m if rand > 0.66
        elsif rand > 0.995
          spew m
        end
		  	return unless m.message.match /(https?:\/\/[^\s]+)/ # return on urls
		  	@markov.parse_string(m.message)
		  end

      def spew(m)
        Timer(rand(3 .. 10), shots: 1) { m.reply("#{m.user.nick}: #{@markov.generate_n_sentences(rand(1..3))}") }
      end

		  def save_dict
		  	@markov.save_dictionary!
		  end

		end
	end
end
