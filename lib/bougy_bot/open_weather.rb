# frozen_string_literal: true

require 'httparty'
require 'ostruct'
require 'pathname'
require_relative './weather'
class OpenWeather
  include BougyBot::Weather
  include HTTParty
  base_uri 'https://api.openweathermap.org/data/2.5'
  API_KEY       = BougyBot.options.open_weather_key.freeze
  API_KEY_PARAM = :APPID
  UNITS_PARAM   = :units
  LANG_PARAM    = :lang

  def weather_by_zip(zip)
    @zone = BougyBot::Zone.find_by_zip(*zip.split(/\s*,\s*/))
    return weather_for_zone(zone) if zone

    options.query[:zip] = zip
    current_weather zip
  end

  def current_weather(query)
    resp = self.class.get '/weather', options.to_h
    return OpenStruct.new(error: "No response for #{query} from #{base_uri}/weather") unless resp

    @weather = OpenStruct.new(resp)
    raise "Error for query '#{query}': #{@weather.message}" if @weather.cod == '404'

    @weather
  end

  def weather_by_id(id)
    options.query[:id] = id
    current_weather id
  end

  def weather_by_latlong(lat, lon)
    options.query[:lat] = lat
    options.query[:lon] = lon
    current_weather [lat, lon]
  end

  def display!(newlines: true)
    return weather.error if weather.error

    main = OpenStruct.new weather.main
    tempf = main.temp
    temp = format '%<f>0.2fF / %<c>0.2fC', f: tempf, c: self.class.f_to_c(tempf)
    @params = OpenStruct.new sys: OpenStruct.new(weather.sys),
                             main: main,
                             temp: temp,
                             wind: OpenStruct.new(weather.wind),
                             unit: UNITS[units],
                             exclamation: self.class.temp_exclamation(tempf, 'imperial')
    @zone ||= BougyBot::Zone.lookup_latlon(*weather.coord.values_at('lat', 'lon'))
    super
  end

  def forecast_by_zip(zip)
    options.query[:zip] = zip
    self.class.get '/forecast', options
  end
end
