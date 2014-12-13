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

    def self.heard(url, name)
      (find(original: url) || new(original: url, by: name)).save
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
      case original
      when /(?:jpg|png|gif)$/
        "Some Random Image named #{File.basename(original)}"
      when /(?:avi|mpg|wmv)$/
        "Some Random Video named #{File.basename(original)}"
      else
        'Untitled Randomness: #{File.basename(original)}'
      end
    end

    def fetch_title
      raw = open(original)
      doc = Nokogiri(raw.read)
      title = doc.xpath('/html/head/title')
      return title.first.text if title && title.first
      default_title
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
