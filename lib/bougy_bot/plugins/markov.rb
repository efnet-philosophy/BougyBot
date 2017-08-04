require 'marky_markov'
require 'cinch'
require 'cinch/cooldown'

module BougyBot
  module Plugins
    class Markov
      EXCLUDED = %w(dionysus).freeze
      include Cinch::Plugin
      enforce_cooldown

      set plugin_name: 'Markov'

      listen_to :channel, method: :execute
      timer 60, method: :save_dict

      def initialize(*args)
        super(*args)
        @markov = MarkyMarkov::Dictionary.new('markov_dictionary')
      end

      def execute(m)
        msg = m.message
        chars = msg.chars
        if m.message =~ /^#{@bot.nick}[:,] /
          spew m if rand < 0.3
        elsif m.message =~ Regexp.new(Regexp.escape(@bot.nick))
          return if rand < 0.5
          spew m
        elsif (chars.select { |t| t =~ /[A-Z]/ }.size.to_f / chars.size.to_f) > 0.5
          spew m, true if rand > 0.9
        elsif rand > 0.998
          spew m
        end
        return if m.message =~ %r{(https?:\/\/[^\s]+)} # return on urls
        @markov.parse_string(m.message)
      end

      def spew(m, upcase = false)
        return if EXCLUDED.include? m.user.nick
        sentences = @markov.generate_n_sentences(rand(1..3))
        msg = upcase ? sentences.upcase : sentences
        Timer(rand(3..10), shots: 1) { m.reply("#{m.user.nick}: #{msg}") }
      end

      def save_dict
        @markov.save_dictionary!
      end
    end
  end
end
