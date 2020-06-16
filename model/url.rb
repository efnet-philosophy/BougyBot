# frozen_string_literal: true
#
require 'nokogiri'
require 'json'
require 'rest-client'
require 'yt'
require 'uri'

Yt.configure do |c|
  c.api_key = BougyBot.options.google.url_api_key
end
# Bot namespace
module BougyBot
  Url = Class.new Sequel::Model
  # Class to hold seen urls
  class Url # rubocop:disable Metrics/ClassLength
    set_dataset :urls
    TINYURL_EXPIRE = 86_400 * 7 # 7 days
    TLIMIT = 256
    plugin :timestamps,
           create: :at,
           update: :last,
           force: true,
           update_on_create: true
    many_to_one :channel
    attr_reader :head

    def self.find_filtered(args)
      res = find(original: args[:original], channel_id: args[:channel_id])
      return res if res
      url = new(args)
      res = find(short: url.short_title) if url.short_title
      return url unless res
      res
    rescue
      binding.pry if $dance_baby # rubocop:disable Lint/Debugger,Style/GlobalVars
    end

    def self.heard(url, name, channel_id)
      u = find_filtered original: url, channel_id: channel_id, by: name
      u.times ||= 0
      u.times += 1
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

    def self.abuser?(nick)
      today = recent 86_400
      soon  = recent 240
      return true if today.size > 200
      return true if soon.size > 30
      return true if today.select { |r| r.by == nick }.size > 24
      soon.select { |r| r.by == nick }.size > 10
    end

    def short_title
      self.title = fetch_title unless title
      return @short_title if @short_title
      st = title.size > TLIMIT ? "#{title[0..TLIMIT]}..." : title
      @short_title = st.tr("\n", ' ').strip
    end

    def ignores
      ['George']
    end

    def display_for(nick)
      return if ignores.include?(nick)
      if old?
        if by == nick
          "#{nick}: You shared this already on #{pretty_at} '#{short_title}' -> #{short} (shared #{times} times)"
        else
          format('%s: OLD! First shared by %s on %s. "%s" (%s) (shared %s times)',
                 nick,
                 by == nick ? 'You' : by,
                 pretty_at,
                 short_title,
                 short,
                 times)
        end
      else
        format('%s: %s (%s)', nick, short_title, short)
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    def pretty_at
      DateTime.parse(at.to_s).httpdate
    end

    def before_save
      self[:times] ||= 0
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
      'Screw this untitled link'
    end

    def head
      require 'net/http'
      @head ||= Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
        http.head(uri.request_uri)
      end
    end

    def uri
      @uri ||= URI.parse(original)
    end

    def url_filtered?(wikipedia, youtube, twitter)
      return true if original =~ %r{https?://en\.wikipedia\.org/wiki/} && wikipedia
      return true if original =~ %r{https?://(www\.youtube\.com/watch\?|youtu.be/)} && youtube
      return true if original =~ %r{https?://((www|mobile)\.)?twitter.com/[^/]*/status/\d+} && twitter
      return true if uri.host == 'sci-hub.cc'
      false
    end

    def filtered_url(wikipedia, youtube, twitter)
      return 'A link to some paper or other science document at the sci-hub sponsored by Moscow' if uri.host == 'sci-hub.cc'
      return wikipedia_synopsis if original =~ %r{https?://en\.wikipedia\.org/wiki/} && wikipedia
      return youtube_synopsis   if original =~ %r{https?://(www\.youtube\.com/watch\?|youtu.be/)} && youtube
      return twitter_synopsis   if original =~ %r{https?://((www|mobile)\.)?twitter.com/[^/]*/status/\d+} && twitter
      raise "Why was a filter called? #{original} #{head.content_type}"
    end

    def http_fetch_title
      Log.info "Getting #{original}"
      open(original) do |raw|
        doc = Nokogiri(raw.read)
        title = doc.xpath('/html/head/title')
        return default_title unless title && title.first
        return title.first.text
      end
    end

    def fetch_title(wikipedia = true, youtube = true, twitter = true)
      return http_fetch_title if uri.host == 'photos.app.goo.gl'
      return filtered_url(wikipedia, youtube, twitter) if url_filtered?(wikipedia, youtube, twitter)
      return "Some stupid #{head.content_type} that no one cares about" unless head.content_type =~ /text/ && uri.host != 'photos.app.goo.gl'
      return "Some giant web page #{head.content_length} bytes long that no one cares about" if head.content_length && head.content_length > 100_000_000
      http_fetch_title
    rescue => e
      info e
      Log.error e
      e.backtrace.each { |err| Log.error err }
      default_title
    end

    def youtube_synopsis
      vurl = URI.parse(original)
      vid = if vurl.host == 'www.youtube.com'
              URI.decode_www_form(vurl.query).to_h['v']
            else
              File.basename vurl.path
            end
      return 'Video Not Found' unless vid
      video = Yt::Video.new id: vid
      return 'Video Not Found' unless video.exists?
      description = video.description.sub(video.title, '').gsub(/[\r\n]/, ' ').squeeze(' ')
      description = description =~ /[a-zA-Z]/ ? format(' - %s', description) : ''
      format('\'%s\' (%s views)%s', video.title, video.view_count, description)
    rescue
      'Error fetching youtube title'
    end

    def twitter_synopsis
      require 'mechanize'
      agent = Mechanize.new
      parsed = URI.parse original
      res = agent.get(File.join('https://twitter.com', parsed.path))
      if res.forms.size == 2
        newres = res.forms.first.submit
        title = newres.css('//div[class="dir-ltr"]')&.first&.text
        return title.strip if title
      end
      "Some tweet that twitter isn't giving a title for"
    end

    def wikipedia_synopsis
      term = File.basename(original)
      req = "http://en.wikipedia.org/w/api.php?action=parse&page=#{term}&format=json&prop=text&section=0"
      r = RestClient.get(req,
                         'USER_AGENT' => 'Philosophy IRC Robot. tj@rubyists.com')

      Nokogiri(JSON.parse(r)['parse']['text']['*'].scan(%r{<p>.*?<\/p>}m).first).text
    # rubocop:enable Metrics/LineLength
    rescue
      fetch_title(false)
    end

    def shorten_url
      return original unless original.size > 30
      if BougyBot.options.google[:url_api_key]
        begin
          google_shortened_url
        rescue
          tinyurl_shortened_url
        end
      else
        tinyurl_shortened_url
      end
    rescue
      original
    end

    private

    def tinyurl_shortened_url
      self.class.tinyurl_shortened_url(original)
    end

    def google_shortened_url
      self.class.google_shortened_url(original)
    end

    public

    def self.tinyurl_shortened_url(url)
      eurl = URI.escape(url)
      tiny_url = open("http://tinyurl.com/api-create.php?url=#{eurl}").read
      tiny_url =~ /Error/ ? url : tiny_url
    end

    def self.google_shortened_url(url)
      u = format('https://www.googleapis.com/urlshortener/v1/url?key=%s',
                 BougyBot.options.google[:url_api_key])
      resp = RestClient.post(u,
                             { longUrl: url }.to_json,
                             content_type: :json)
      props = JSON.parse resp
      props.key?('id') ? props['id'] : url
    end
  end
end
