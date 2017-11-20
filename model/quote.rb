# frozen_string_literal: true
require 'open-uri'
require 'nokogiri'
# Bot namespace
module BougyBot
  def self.uncommand(s)
    s.sub(/^([!\.])/, '> \1')
  end
  # A string that send itself to #display
  class Dstring
    attr_reader :display
    def initialize(string)
      @display = string
    end
  end

  def self.randit
    if (6..14).to_a.include?(Time.now.utc.hour) && !BougyBot.options[:nodoze]
      puts 'Bed Time, long sleep!' if BougyBot.options[:debug]
      return 7 * 60 * 60
    end
    rand BougyBot.options.sleeps.sample
  end

  def self.html_for_url(url)
    r = randit
    puts "sleeping #{r} then getting #{url}" if BougyBot.options[:debug]
    sleep r
    open(url).read
  end

  Quote = Class.new(Sequel::Model)
  # A quote
  class Quote
    set_dataset :quotes

    def self.author_quotes(string)
      author, *q = string.split
      au_ds = filter(author: /\y#{author}\y/i)
      au_ds = au_ds.filter(quote: /\y#{q.join(" ")}\y/i) unless q.empty?
      (au_ds.all + filter(author: /\y#{string}\y/i).all).compact
    end

    # return value must respond to #display
    def self.best(query)
      raw_quotes = filter(quote: /\y#{query}\y/).all
      aquotes = author_quotes(query)
      q = (aquotes + raw_quotes).uniq.compact.sample
      q || Dstring.new('No Dice')
    rescue => e
      warn "Wtf in best? #{e}"
      Dstring.new('No Dice')
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
      format('%s -- %s', BougyBot.uncommand(quote), author)
    end
  end

  # Brainyquotes support
  class Brainy
    attr_reader :url, :name
    BARE = 'http://www.brainyquote.com'

    def self.prune_ignores(links, ignore)
      dbg = BougyBot.options[:debug]
      fnames = links.map { |l| File.basename(l, '.html') }
      if fnames.include?(ignore)
        ind = fnames.index(ignore) + 1
        puts "Ignoring #{ind} links on this page" if dbg
        return [links[ind..-1], nil]
      end
      puts "Ignoring all #{links.size} links on this page" if dbg
      [[], ignore]
    end

    def self.unignored_links(links,  ignore)
      links, ignore = prune_ignores(links, ignore) if ignore
      [links.sort { rand(10) <=> rand(10) }, ignore] # rubocop:disable Lint/UselessComparison
    end

    def self.links_to_quotes(links, ignore = nil)
      ls, ignore = unignored_links(links, ignore)
      quotes = ls.map do |link|
        f = File.basename(link, '.html')
        from_name(f).map(&:quotes).flatten
      end
      [quotes, ignore]
    end

    def self.get_all_for(letter, ignore = nil)
      links, doc = all_authors(letter)
      some, ignore = links_to_quotes(links, ignore)
      if np = next_page(doc)
        puts "Next page is #{np}" if BougyBot.options[:debug]
        binding.pry if BougyBot.options[:debugger] # rubocop:disable all
        nl = File.basename np, '.html'
        puts "Next letter is #{nl}" if BougyBot.options[:debug]
        more, ignore = get_all_for(nl, ignore)
        some += more
      end
      some
    end
    # rubocop:enable Metrics/AbcSize

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
      link = "#{BARE}/quotes/authors/%s/%s.html"
      pages = []
      pages << new(format(link, name[0, 1], name), name)
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
