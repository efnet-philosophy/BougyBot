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

  Quote = Class.new(Sequel::Model)
  # A quote
  class Quote
    set_dataset :quotes

    def self.best(query)
      q = filter(Sequel.or(author: /\y#{query}\y/i, quote: /\y#{query}\y/i)).all.sample
      q || Dstring.new('No Dice')
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
    BARE = 'http://www.brainyquote.com/'

    def self.all_authors(letter)
      link = "http://www.brainyquote.com/quotes/#{letter}.html"
      page = open(link).read
      Nokogiri(page)
    end

    def self.next_page(doc)
      doc.css('div.pagination').first.css('li>a').detect do |t|
        t.text == 'Next'
      end[:href]
    rescue
      nil
    end

    def self.from_name(name)
      link = 'http://www.brainyquote.com/quotes/authors/%s/%s.html'
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
      @page ||= open(url).read
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

__END__

require 'open-uri'
page = open('http://www.brainyquote.com/quotes/authors/b/bill_murray.html').read;nil
doc = Nokogiri(page);nil
doc
doc.css('span[class:bqQuoteLink')
doc.css('span[class=bqQuoteLink')
doc.css('span[class=bqQuoteLink]')
doc.css('span[class=bqQuoteLink]').first
qs = doc.css('span[class=bqQuoteLink]');nil
qs.size
qs.first
qs.first.xpath("/a")
qs.first.xpath("//a")
qs.first.xpath("a")
qs.first.xpath("a").text
qs.map { |n| n.xpath('a').text }
qs.first
qs.first.siblings
qs.first.sibling
qs.first.next
qs.first.next.next
qs.first.next.next.next
qs.first.next.next.next.next
qs.first.next.next.next.next.next
qs.first.next.next.next.next.next.next
qs.first.next.siblings
qs.first.next
that = _
that.public_methods(false)
that.public_methods
that.next_sibling
that.next_sibling.next_sibling
that.parent
that.parent.parent
qs.first.parent
qs.first.parent.parent
qdivs = doc.css('div[class=bqQt]');nil
qdivs.first
qs.first.parent.parent
qdivs = doc.css('div.bqQt]');nil
qdivs = doc.css('div.bqQt');nil
qdivs.first
qdivs.first.css('div.bq_boxyRelatedLeft')
qdivs.first.css('div.bq_boxyRelatedLeft').text
qdivs.first.css('div.bq_boxyRelatedLeft>a')
qdivs.first.css('div.bq_boxyRelatedLeft>a').first
qdivs.first.css('div.bq_boxyRelatedLeft>a').first.text
qdivs.first.css('div.bq_boxyRelatedLeft>a')
exit
