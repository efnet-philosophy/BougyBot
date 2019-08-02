# frozen_string_literal: true
require 'httparty'
require 'json'
require 'cgi'
module BougyBot
  class GoogleSearch
    attr_accessor :google_api_key, :csn
    def initialize(q, google_api_key = BougyBot.options.google.url_api_key)
      @results        = []
      @q              = q
      @google_api_key = google_api_key if google_api_key
      @cse            = '014887693395666501734:fslwrlkmhfm'
    end

    def display(limit = 2)
      results[0..(limit - 1)].map do |result|
        format('%s (%s)',
               result[:description],
               result[:link])
      end.join(' || ')
    end

    def results
      return @results if @results.size.positive?
      json = fetch
      return @results if json.nil?
      if json['items']
        @results = json['items'][0 .. 1].map do |item|
          h = { title: item['title'] }
          h[:description] = item['snippet'].delete("\n")
          h[:link]        = (Url.tinyurl_shortened_url(item['link']) rescue item['link'])
          h
        end
      else
        @results
      end
    end

    private

    def url
      @url ||= format('https://www.googleapis.com/customsearch/v1?key=%s&cx=%s&q=%s',
                      @google_api_key,
                      @cse,
                      CGI.escape(@q))
    end

    def fetch
      res = ::HTTParty.get(url)
      return nil unless res
      res
    end
  end
end
