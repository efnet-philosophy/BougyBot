require 'open-uri'
require 'nokogiri'

module Cinch
  module Plugins
    # The haiku thing
    class Haiku
      include ::Cinch::Plugin
      attr_accessor :haiku

      match 'haiku', method: :haiku
      match 'htoggle', method: :toggle
      def initialize(*args)
        super
        @haiku = {}
      end

      def toggle(m)
        return unless m.user.nick =~ /death_syn|bougyman/i
        @haiku[m.channel.name] = @haiku[m.channel.name] ? false : true
      end

      def haiku(m)
        return unless @haiku[m.channel.name]
        html = Nokogiri::HTML(open("http://www.dailyhaiku.org/haiku/?pg=#{rand(220) + 1}")) # rubocop:disable Metrics/LineLength
        haikus = html.search('p.haiku').to_a
        haiku_lines = haikus.sample.text.split(/[\r\n]+/)

        # width = haiku_lines.inject(0) { |max, line|
        #   [line.length, max].max
        # }

        m.reply haiku_lines.map(&:strip).join(' / ')
        # haiku_lines.each do |line|
        #  sleep config[:delay] if config[:delay]
        #  m.reply('     ' + line.center(width))
        # end
      end
    end
  end
end
