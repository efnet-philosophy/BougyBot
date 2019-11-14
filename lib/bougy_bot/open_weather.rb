# frozen_string_literal: true

require 'httparty'
require 'ostruct'
require 'pathname'
require_relative '../bougy_bot'
BougyBot::R 'db/init'
BougyBot::M 'zone'
class OpenWeather # rubocop:disable Metrics/ClassLength
  include HTTParty
  base_uri 'https://api.openweathermap.org/data/2.5'
  TEMPLATE_PATH = BougyBot::ROOT / :templates
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
      -100..-20 => 'So fucking cold just breathing will freeze your lungs',
      -20..0    => 'Freezing your pee before it hits the ground COLD',
      0..15     => 'Colder than a witches tit',
      15..25    => 'Freeze your tits off cold',
      25..29    => 'Coors Light Optimum Temperature',
      29..32    => 'A cunt hair shy of freezing',
      32..40    => 'Nipple-hardening cold',
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

  def self.display_for_zip(zip)
    new(BougyBot.options.open_weather_key, units: 'imperial').display_for_zip zip
  end

  def self.display_for_query(query)
    new(BougyBot.options.open_weather_key, units: 'imperial').display_for_query query
  end

  def self.direction_from_degree(degree)
    return 'Void' unless degree
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
    q = @options.dup
    q[:query][:zip] = zip
    self.class.get '/weather', q
  end

  def weather_by_query(query)
    city, country = query.split(/\s*,\s*/)
    zone = BougyBot::Zone.lookup_city city, country
    return({ 'cod' => '404', 'message' => "Nothing found for #{query}" }) unless zone

    q = @options.dup
    if zone.name.match(/^\d+$/)
      q[:query][:id] = zone.name
    else
      q[:query][:lat] = zone.latitude
      q[:query][:lon] = zone.longitude
    end
    self.class.get '/weather', q
  end

  def display(weather)
    tpl = ERB.new(File.read(TEMPLATE_PATH.join('weather.erb')))
    main = OpenStruct.new(weather.main)
    temp = main.temp
    sys = OpenStruct.new weather.sys
    wind = OpenStruct.new weather.wind
    unit = UNITS[options[:query][:units]]
    name = sane_name(weather, main.name)
    tpl.result(binding).chomp
  end

  def sane_name(weather, name)
    region, country = BougyBot::Zone.lookup_latlon(*weather.coord.values_at('lat', 'lon')).to_h.values_at(
      :name,
      :country
    )
    if name.nil?
      region = 'Nowhere' if region.nil?
      return country if region == country
      return region if country.nil?

      "#{region}, #{country}"
    else
      return "#{name}, #{country}" if name == region

      "#{name}, #{region}, #{country}"
    end
  end

  def display_for_query(query)
    weather = weather_by_query query
    return weather['message'] if weather['cod'] == '404'

    display OpenStruct.new(weather)
  end

  def display_for_zip(zip)
    weather = weather_by_zip zip
    return weather['message'] if weather['cod'] == '404'

    display OpenStruct.new(weather)
  end

  def temp_exclamation(temp)
    te = TEMP_EXCLAMATIONS[options[:query][:units]]
    return '' unless te

    te[te.keys.detect { |k| k.cover? temp }]
  end

  def forecast_by_zip(zip)
    options[:query][:zip] = zip
    self.class.get '/forecast', options
  end
end
