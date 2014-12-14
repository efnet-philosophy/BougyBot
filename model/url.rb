require 'nokogiri'
require 'json'
require 'rest-client'
# Bot namespace
module BougyBot
  Url = Class.new Sequel::Model
  # Class to hold seen urls
  class Url
    set_dataset :urls
    TINYURL_EXPIRE = 86_400 * 7 # 7 days
    plugin :timestamps,
           create: :at,
           update: :last,
           force: true,
           update_on_create: true
    many_to_one :channel

    def self.heard(url, name, channel_id)
      u = find original: url, channel_id: channel_id
      u ||= new(original: url, by: name, channel_id: channel_id)
      u.save
    end

    def self.recent
      order(Sequel.desc(:last)).limit(35).all.select do |r|
        Time.now - r.last < 180
      end
    end

    def self.abuser?(nick)
      return true if recent.size > 30
      recent.select { |r| r.by == nick }.size > 10
    end

    def old?
      times > 1
    end

    def display_for(nick)
      if old?
        format('%s: OLD! First shared by %s %s. "%s" (%s)',
               by,
               by == nick ? 'You' : by,
               pretty_at,
               title,
               short)
      else
        format('%s: "%s" (%s)', by, title, short)
      end
    end

    private

    def pretty_at
      DateTime.parse(at.to_s).httpdate
    end

    def before_save
      self[:times] ||= 0
      self[:times] += 1
      self[:title] ||= fetch_title
      self[:short] ||= shorten_url
      self[:last]  ||= Time.now
      self[:short] = shorten_url if old_tiny?
      super
    end

    def old_tiny?
      Time.now - last > TINYURL_EXPIRE
    end

    def default_title
      fname = File.basename(original)
      case fname
      when /(?:jpg|png|gif)$/
        "Some Random Image named #{fname}"
      when /(?:avi|mpg|wmv)$/
        "Some Random Video named #{fname}"
      else
        "Untitled Randomness: #{fname}"
      end
    end

    # rubocop:disable Metrics/LineLength
    # urls are long, mmkay?
    def fetch_title(wikipedia = true)
      return wikipedia_synopsis if original =~ %r{https://en\.wikipedia\.org/wiki/} && wikipedia
      raw = open(original)
      doc = Nokogiri(raw.read)
      title = doc.xpath('/html/head/title')
      return title.first.text if title && title.first
      default_title
    end

    def wikipedia_synopsis
      term = File.basename(original)
      req = "http://en.wikipedia.org/w/api.php?action=parse&page=#{term}&format=json&prop=text&section=0"
      r = RestClient.get(req,
                         'USER_AGENT' => 'Philosophy IRC Robot. tj@rubyists.com')

      Nokogiri(JSON.parse(r)['parse']['text']['*'].scan(/<p>.*?<\/p>/m).first).text
    # rubocop:enable Metrics/LineLength
    rescue
      fetch_title(false)
    end

    def shorten_url
      return original unless original.size > 30
      eurl = URI.escape(original)
      tiny_url = open("http://tinyurl.com/api-create.php?url=#{eurl}").read
      tiny_url =~ /Error/ ? original : tiny_url
    rescue
      url
    end
  end
end
