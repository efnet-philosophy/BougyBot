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
    TEMP_EXCLAMATIONS = JSON.parse(BougyBot::ROOT.join('data/temp_sayings.json').read).freeze

    def self.included(klass)
      klass.extend ClassMethods
    end

    def self.display_for_zip(zip, newlines: true)
      OpenWeather.display_for_zip zip, newlines: newlines
    end

    def self.display_for_query(query, newlines: true)
      OpenWeather.display_for_query query, newlines: newlines
    end

    def self.display_for_zone(zone, newlines: true)
      OpenWeather.display_for_zone zone, newlines: newlines
    end

    module ClassMethods
      def f_to_c(float)
        ((float - 32) * 5) / 9.0
      end

      def exclamation_hash
        @exclamation_hash ||= TEMP_EXCLAMATIONS.keys.each_with_object({}) do |key, obj|
          obj[key] = TEMP_EXCLAMATIONS[key].keys.each_with_object({}) do |rkey, robj|
            min, max = rkey.split('..').map(&:to_i)
            robj[min..max] = TEMP_EXCLAMATIONS[key][rkey]
          end
        end
      end

      def temp_exclamation(temp, units)
        te = exclamation_hash[units]
        return '' unless te

        match = te[te.keys.detect { |k| k.cover? temp }]
        return 'An indescribable temperature' unless match

        match.sample
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
      zon = BougyBot::Zone.lookup_city city, country
      raise "Nothing found, querying for #{query}" unless zon

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
