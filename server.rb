require 'rubygems'
require 'sinatra'
require 'rest_client'
require 'json'
require 'haml'
require 'sass'
require 'will_paginate'

configure do
  set :db, 'http://localhost:5984/deposits'
end

get '/' do
  "hello"
end

get '/:year/?' do
  view = "_design/data/_view/by_year"
  
  year = params[:year]
  year = "2010" if year.nil?
  
  data_url = "#{settings.db}/#{view}?key=%22#{year}%22"
  
  @results, @total_records = get_data(data_url, 10, 1)
  
  haml :deposit_list
end

get '/:year/:page/?' do
  view = "_design/data/_view/by_year"
  year = params[:year]
  year = "2010" if year.nil?
  
  data_url = "#{settings.db}/#{view}?key=%22#{year}%22"
  
  @results, @total_records = get_data(data_url, 10, params[:page])
  
  haml :deposit_list
end

private
  def get_data url, records_per_page, current_page=1
    data = RestClient.get url
    rows = JSON.parse(data.body)["rows"]
    total_records = rows.count
    results = rows.paginate({:page => current_page, :per_page => records_per_page})
    [results, total_records]
  end