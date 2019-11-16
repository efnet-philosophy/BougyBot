# frozen_string_literal: true

require 'httparty'
require 'ostruct'
require 'pathname'
require_relative '../bougy_bot'
module BougyBot
  R 'db/init'
  M 'zone'
  module Weather
    TEMPLATE_PATH = BougyBot::ROOT / :templates
    API_KEY = to_s.freeze
    DIRECTIONS = {
      0..5     => :north,
      6..39    => :north_north_west,
      40..50   => :north_west,
      51..84   => :west_north_west,
      85..95   => :west,
      96..129  => :west_south_west,
      130..140 => :south_west,
      141..174 => :south_south_west,
      175..185 => :south,
      186..219 => :south_south_east,
      220..230 => :south_east,
      231..264 => :east_south_east,
      265..275 => :east,
      276..309 => :east_north_east,
      310..320 => :north_east,
      321..354 => :north_north_east,
      355..360 => :north
    }.freeze
    DEFAULT_UNIT = { pressure: 'hPa', distance: 'meters', speed: 'meter/sec' }.freeze
    UNITS = {
      'imperial' => OpenStruct.new(DEFAULT_UNIT.merge(temp: 'F', distance: 'feet', speed: 'mph')),
      'metric'   => OpenStruct.new(DEFAULT_UNIT.merge(temp: 'C')),
      'Standard' => OpenStruct.new(DEFAULT_UNIT.merge(temp: 'Kelvin'))
    }.freeze
    TEMP_EXCLAMATIONS = {
      'imperial' => {
        -100..-40 => 'As if you landed on Uranus. No heat whatsoever',
        -40..-20  => 'So fucking cold just breathing will freeze your lungs',
        -20..0    => 'Freezing your pee before it hits the ground COLD',
        0..15     => "Colder than a witch's tit. Stay inside.",
        15..25    => 'Freeze your tits off cold. Layers!',
        25..29    => 'Coors Light Optimum Temperature. Bundle up.',
        29..32    => 'A cunt hair below freezing',
        32..32    => 'Exactly: Freezing',
        32..34    => 'A cunt hair shy of freezing. Check your faucets!',
        34..40    => 'Cold as fuck. Grab a jacket',
        40..50    => 'A litle chilly. Grab a sweater',
        50..60    => 'Mild, on the chill side',
        60..70    => 'Perfectly Mild',
        70..80    => 'Absolutely Beautiful',
        80..90    => 'Shorts & T-shirt weather',
        90..100   => 'Heating up pretty solidly. Pets come inside',
        100..110  => 'Hot as fuck',
        110..120  => "Approaching Satan's Comfort Level",
        120..130  => 'A fucking Inferno',
        (130..)   => 'Literally in flames'
      }
    }.freeze

    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def temp_exclamation(temp, units)
        te = TEMP_EXCLAMATIONS[units]
        return 'An impossible temperature. What the hell is going on there?' unless te

        te[te.keys.detect { |k| k.cover? temp }]
      end

      def display_for_zip(zip, newlines: true)
        (w = new(units: 'imperial')).weather_by_zip(zip)
        w.display! newlines: newlines
      end

      def display_for_query(query, newlines: true)
        (w = new(units: 'imperial')).weather_by_query(query)
        w.display! newlines: newlines
      end

      def display_for_zone(zone, newlines: true)
        (w = new(units: 'imperial')).weather_for_zone(zone)
        w.display! newlines: newlines
      end

      def direction_from_degree(degree)
        return 'Void' unless degree
        raise "Degree '#{degree}' must be between 0 and 360" unless (0..360).cover? degree

        dir = DIRECTIONS[DIRECTIONS.keys.detect { |k| k.cover? degree }]
        raise "Direction #{degree} not found!" unless dir

        dir.to_s.split('_').map { |n| n[0].upcase }.join
      end
    end

    attr_reader :options, :params, :weather
    attr_accessor :zone, :units, :lang, :time
    def initialize(units: 'metric', lang: 'en_us', zone: nil, time: Time.now)
      api_key_param = self.class.const_get :API_KEY_PARAM
      units_param   = self.class.const_get :UNITS_PARAM
      lang_param    = self.class.const_get :LANG_PARAM
      @options = OpenStruct.new query: {
        units_param   => units,
        lang_param    => lang,
        api_key_param => self.class.const_get(:API_KEY)
      }
      @lang = lang
      @time = time
      @zone = zone
      @units = units
    end

    def weather_for_zone(zon)
      @zone = zon
      return weather_by_id(zone.name) if zone.name.match?(/^\d+$/)

      weather_by_latlong(zone.latitude, zone.longitude)
    end

    def weather_by_query(query)
      city, country = query.split(/\s*,\s*/)
      @zone ||= BougyBot::Zone.lookup_city city, country

      weather_for_zone(zon)
    end

    def display!(newlines: true)
      return weather.error if weather.error

      p = params
      tpl = ERB.new(File.read(TEMPLATE_PATH.join("#{self.class.name}-current.erb")))
      res = tpl.result(binding).chomp
      return res if newlines

      res.tr("\n", ' ')
    end
  end
end
