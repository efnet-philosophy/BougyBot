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
    TLIMIT = 256
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

    def self.recent(secs = 180)
      order(Sequel.desc(:last)).limit(35).all.select do |r|
        Time.now - r.last < secs
      end
    end

    def old?
      times > 1
    end

    # rubocop:disable Metrics/AbcSize
    def self.abuser?(nick)
      today = recent 86_400
      soon  = recent 240
      return true if today.size > 200
      return true if soon.size > 30
      return true if today.select { |r| r.by == nick }.size > 24
      soon.select { |r| r.by == nick }.size > 10
    end

    def short_title
      return @short_title if @short_title
      st = title.size > TLIMIT ? "#{title[0..TLIMIT]}..." : title
      @short_title = st.gsub(/\n/, ' ').strip
    end

    def display_for(nick)
      if old?
        format('%s: OLD! First shared by %s on %s. "%s" (%s)',
               nick,
               by == nick ? 'You' : by,
               pretty_at,
               short_title,
               short)
      else
        format('%s: "%s" (%s)', nick, short_title, short)
      end
    end
    # rubocop:enable Metrics/AbcSize

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
      return wikipedia_synopsis if original =~ %r{https?://en\.wikipedia\.org/wiki/} && wikipedia
      raw = open(original)
      doc = Nokogiri(raw.read)
      title = doc.xpath('/html/head/title')
      return default_title unless title && title.first
      title.first.text
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
