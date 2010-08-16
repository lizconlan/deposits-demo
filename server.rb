require 'sinatra'
require 'rest_client'
require 'json'
require 'haml'
require 'sass'

configure do
  if ENV['RACK_ENV'] && ENV['RACK_ENV'] == 'production'
    db = ENV['COUCH_URL']
  else
    conf = YAML.load(File.read('config/virtualserver/config.yml'))
    db = conf[:couch_url]
  end
  set :db, db
  set :page_length, 10
end

get '/favicon.ico' do
  ""
end

get '/portrait.css' do
  content_type 'text/css', :charset => 'utf-8'
  if request.user_agent =~ /(iPhone|iPad)/
    sass :"#{$1.downcase()}_portrait"
  end
end

get '/landscape.css' do
  content_type 'text/css', :charset => 'utf-8'
  if request.user_agent =~ /(iPhone|iPad)/
    sass :"#{$1.downcase()}_landscape"
  end
end

get '/styles.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :styles
end

get '/mobile.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :mobile
end

get '/' do
  page_length = settings.page_length
  page_length = 6 if request.user_agent =~ /iPad/
  
  view = "_design/data/_view/by_id"
  
  columns = 3
  columns = 2 if request.user_agent =~ /iPhone/
  
  data_url = "#{settings.db}/#{view}?descending=true"
  
  if request.user_agent =~ /iPad/
    @col1 = get_data(data_url, 6, 1)
  else  
    @col1 = get_data(data_url, settings.page_length, 1)
    @col2 = get_data(data_url, settings.page_length, 2)
    if columns == 3
      @col3 = get_data(data_url, settings.page_length, 3)
    end
  end
  
  @year = @params[:year]
  @year = "2010" if @year.nil? #needs to be better
  @session = get_session(@year)
  
  #get the number of records
  data = RestClient.get "#{settings.db}/_design/data/_view/count_by_year?key=%22#{@year}%22&group=true"
  rows = JSON.parse(data.body)["rows"]
  @total_records = rows[0]["value"].to_i
  @current_page = 1
  @max_pages = (@total_records / page_length).ceil
  
  haml :index
end

get '/' do
  request.user_agent.include?('iPad').inspect
end


get '/:year/?' do
  view = "_design/data/_view/by_year"
  
  @year = @params[:year]
  @year = "2010" if @year.nil?
  @session = get_session(@year)
  
  #get the number of records
  data = RestClient.get "#{settings.db}/_design/data/_view/count_by_year?key=%22#{@year}%22&group=true"
  rows = JSON.parse(data.body)["rows"]
  @total_records = rows[0]["value"].to_i
  
  #get the records themselves
  data_url = "#{settings.db}/#{view}?key=%22#{@year}%22"
  @results = get_data(data_url, settings.page_length, 1)
  
  haml :deposit_list
end

get '/:year/:page/?' do
  view = "_design/data/_view/by_year"
  @year = params[:year]
  @year = "2010" if @year.nil?
  @session = get_session(@year)
  
  #get the number of records
  data = RestClient.get "#{settings.db}/_design/data/_view/count_by_year?key=%22#{@year}%22&group=true"
  rows = JSON.parse(data.body)["rows"]
  @total_records = rows[0]["value"].to_i
  
  #get the records themselves
  data_url = "#{settings.db}/#{view}?key=%22#{@year}%22"
  @results = get_data(data_url, settings.page_length, params[:page])
  
  haml :deposit_list
end

private
  def get_data url, records_per_page, current_page=1
    if url.include?("?")
      url = "#{url}&limit=#{records_per_page.to_i()+1}&skip=#{records_per_page.to_i()*(current_page.to_i()-1)}"
    else
      url = "#{url}?limit=#{records_per_page.to_i()+1}&skip=#{records_per_page.to_i()*(current_page.to_i()-1)}"
    end
    data = RestClient.get url
    
    JSON.parse(data.body)["rows"]
  end
  
  def get_session year
    case year
      when "pre2007", "2007", nil
        nil
      else
        year_end = year.to_i
        year_start = year_end - 1
        "#{year_start} - #{year_end}"
    end
  end
