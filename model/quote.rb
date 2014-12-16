require 'open-uri'
require 'nokogiri'
# Bot namespace
module BougyBot
  # A string that send itself to #display
  class Dstring
    attr_reader :display
    def initialize(string)
      @display = string
    end
  end

  def self.html_for_url(url)
    puts "getting #{url}" if BougyBot.options[:debug]
    sleep rand(10)
    open(url).read
  end

  Quote = Class.new(Sequel::Model)
  # A quote
  class Quote
    set_dataset :quotes

    # return value must respond to #display
    def self.best(query)
      user = User.find(nick: query)
      if user
        log = ChanLog.filter(user_id: user.id).all.sample
        return Dstring.new(format('%s -- %s', log.message, user.nick))
      end
      q = filter(Sequel.or(author: /\y#{query}\y/i, quote: /\y#{query}\y/i)).all.sample # rubocop:disable Metrics/LineLength
      q || Dstring.new('No Dice')
    end

    def self.summary
      "#{Quote.count} quotes by #{Quote.distinct(:author).count} people"
    end

    def self.create_or_update(quote, author, tags)
      me = find(quote: quote)
      return me if me
      create quote: quote, author: author, tags: tags
    end

    def self.sample
      order(Sequel.function(:random)).limit(1).first
    end

    def display
      format('%s -- %s', quote, author)
    end
  end

  # Brainyquotes support
  class Brainy
    attr_reader :url, :name
    #BARE = 'http://www.brainyquote.com'
    BARE = 'http://[2400:cb00:2048:1::be5d:f01a]'

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength
    def self.get_all_for(letter, ignore_until = nil)
      ignore = ignore_until
      one, doc = all_authors(letter)
      some = one.map do |link|
        l = File.join(BARE, link)
        f = File.basename(link, '.html')
        if ignore && ignore_until != f
          puts "Ignoring #{f}" if BougyBot.options[:debug]
          next
        elsif ignore && ignore_until == f
          puts "We got #{f}, stop ignoring" if BougyBot.options[:debug]
          ignore = false
          next
        end
        from_name(f).map { |n| n.quotes }.flatten
      end.compact
      if np = next_page(doc) # rubocop:disable Lint/AssignmentInCondition
        puts "Next page is #{np}" if BougyBot.options[:debug]
        binding.pry if BougyBot.options[:debugger] # rubocop:disable all
        nl = File.basename np, '.html'
        puts "Next letter is #{nl}" if BougyBot.options[:debug]
        some += get_all_for(nl)
      end
      some
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength

    def self.all_authors(letter)
      link = "#{BARE}/quotes/#{letter}.html"
      page = BougyBot.html_for_url(link)
      doc = Nokogiri(page)
      author_urls = doc.css('div.bq_s>table')
                    .first
                    .css('a').map { |n| n[:href] }
      [author_urls, doc]
    end

    def self.next_page(doc)
      doc.css('div.pagination').first.css('li>a').detect do |t|
        t.text == 'Next'
      end[:href]
    rescue
      nil
    end

    def self.from_name(name)
      link = format('%s/quotes/authors/%s/%s.html', BARE)
      pages = []
      pages << new(format(link, name[0, 1], name), name)
      # rubocop:disable Lint/AssignmentInCondition
      while npage = pages.last.next_page
        pages << new(File.join(BARE, npage), name)
      end
      # rubocop:enable Lint/AssignmentInCondition
      pages
    end

    def initialize(url, name = nil)
      @name = name || File.basename(url, '.html')
      @url = url
    end

    def quotes
      @quotes ||= quote_divs.map do |div|
        Quote.create_or_update(quote(div), author(div), tags(div))
      end
    end

    def next_page
      Brainy.next_page(doc)
    end

    private

    def page
      @page ||= BougyBot.html_for_url(url)
    end

    def doc
      @doc ||= Nokogiri(page)
    end

    def quote_divs
      @quote_divs ||= doc.css('div.bqQt')
    end

    def author(div)
      div.css('div.bq-aut>a').text
    end

    def quote(div)
      div.css('span.bqQuoteLink>a').text
    end

    def tags(div)
      div.css('div.bq_boxyRelatedLeft>a').map(&:text)
    end
  end
end
