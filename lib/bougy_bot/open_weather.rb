# frozen_string_literal: true

require 'httparty'
require 'ostruct'
require 'pathname'
class OpenWeather
  include HTTParty
  base_uri 'https://api.openweathermap.org/data/2.5'
  TEMPLATE_PATH = Pathname('templates')
  DIRECTIONS = {
    0..5 => :north,
    6..39 => :north_north_west,
    40..50 => :north_west,
    51..84 => :west_north_west,
    85..95 => :west,
    96..129 => :west_south_west,
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
  def self.direction_from_degree(degree)
    raise "Degree '#{degree}' must be between 0 and 360" unless (0..360).cover? degree

    dir = DIRECTIONS[DIRECTIONS.keys.detect { |k| k.cover? degree }]
    raise "Direction #{degree} not found!" unless dir

    dir.to_s.split('_').map { |n| n[0].upcase }.join
  end

  attr_reader :options
  def initialize(api_key, units: 'metric', lang: 'en_us')
    @options = { query: { APPID: api_key, units: units, lang: lang } }
  end

  def weather_by_zip(zip)
    options[:query][:zip] = zip
    self.class.get '/weather', options
  end

  def display_for_zip(zip)
    weather = OpenStruct.new(weather_by_zip(zip))
    tpl = ERB.new(File.read(TEMPLATE_PATH.join('weather.erb')))
    main = OpenStruct.new weather.main
    sys = OpenStruct.new weather.sys
    wind = OpenStruct.new weather.wind
    conditions = weather.weather
    tpl.result(binding).chomp
  end

  def forecast_by_zip(zip)
    options[:query][:zip] = zip
    self.class.get '/forecast', options
  end
end
