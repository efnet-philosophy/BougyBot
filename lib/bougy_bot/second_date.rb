require 'rss'
require 'open-uri'
module BougyBot
  class SecondDate
    RSS_FEED = BougyBot::ROOT.join('config/second_date.rss')

    def self.best(query = nil)
      items = new.rss.items
      if query
        items.select do |item|
          (item.summary rescue item.description) =~ /#{query}/i
        end.sample
      else
        items.sample
      end
    end

    def rss
      @rss ||= RSS::Parser.parse data
    end

    def data
      RSS_FEED.exist? ? RSS_FEED.read : open('http://cdn.stationcaster.com/stations/kscs/rss/9771.rss').read
    end
  end
end
