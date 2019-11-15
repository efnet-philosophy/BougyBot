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

  def self.display_for_zip(zip)
    new(BougyBot.options.open_weather_key, units: 'imperial').display_for_zip zip
  end

  def self.display_for_query(query)
    new(BougyBot.options.open_weather_key, units: 'imperial').display_for_query query
  end

  def self.display_for_zone(zone)
    new(BougyBot.options.open_weather_key, units: 'imperial').display_for_zone zone
  end

  def self.direction_from_degree(degree)
    return 'Void' unless degree
    raise "Degree '#{degree}' must be between 0 and 360" unless (0..360).cover? degree

    dir = DIRECTIONS[DIRECTIONS.keys.detect { |k| k.cover? degree }]
    raise "Direction #{degree} not found!" unless dir

    dir.to_s.split('_').map { |n| n[0].upcase }.join
  end

  attr_reader :options
  attr_accessor :zone
  def initialize(api_key, units: 'metric', lang: 'en_us', zone: nil)
    @zone = zone
    @options = { query: { APPID: api_key, units: units, lang: lang } }
  end

  def weather_by_zip(zip)
    q = @options.dup
    @zone = BougyBot::Zone.find_by_zip(*zip.split(/\s*,\s*/))
    return weather_for_zone(zone) if zone

    q[:query][:zip] = zip
    self.class.get '/weather', q
  end

  def weather_by_query(query)
    city, country = query.split(/\s*,\s*/)
    @zone ||= BougyBot::Zone.lookup_city city, country
    return({ 'cod' => '404', 'message' => "Nothing found for #{query}" }) unless zone

    weather_for_zone(zon)
  end

  def weather_by_id(id)
    q = @options.dup
    q[:query][:id] = id
    self.class.get '/weather', q
  end

  def weather_by_latlong(lat, lon)
    q = @options.dup
    q[:query][:lat] = lat
    q[:query][:lon] = lon
    self.class.get '/weather', q
  end

  def weather_for_zone(zon)
    @zone = zon
    return weather_by_id(zone.name) if zone.name.match?(/^\d+$/)

    weather_by_latlong(zone.latitude, zone.longitude)
  end

  def display(weather)
    tpl = ERB.new(File.read(TEMPLATE_PATH.join('weather.erb')))
    main = OpenStruct.new(weather.main)
    temp = main.temp
    sys = OpenStruct.new weather.sys
    wind = OpenStruct.new weather.wind
    unit = UNITS[options[:query][:units]]
    @zone ||= BougyBot::Zone.lookup_latlon(*weather.coord.values_at('lat', 'lon'))
    tpl.result(binding).chomp
  end

  def display_for_zone(zon)
    weather = weather_for_zone zon
    return weather['message'] if weather['cod'] == '404'

    display OpenStruct.new(weather)
  end

  def display_for_query(query)
    weather = weather_by_query query
    weather['name'] = query if weather['name'].nil? || weather['name'].empty?
    return weather['message'] if weather['cod'] == '404'

    display OpenStruct.new(weather)
  end

  def display_for_zip(zip)
    weather = weather_by_zip zip
    weather['name'] = zip if weather['name'].nil? || weather['name'].empty?
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
