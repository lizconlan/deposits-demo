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

get '/cache.manifest' do
  content_type 'text/manifest'
  "CACHE MANIFEST\n\nimages/next.png\nimages/prev.png"
end

get '/' do
  column_length = get_column_length(request.user_agent)
  
  view = "_design/data/_view/by_id"
  
  data_url = "#{settings.db}/#{view}?descending=true"
  
  case request.user_agent
    when /iPad|iPhone/
      @data = get_data(data_url, column_length, 1)
      page_length = column_length
    else
      @col1 = get_data(data_url, column_length, 1)
      @col2 = get_data(data_url, column_length, 2)
      @col3 = get_data(data_url, column_length, 3)
      page_length = column_length * 3
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

get '/page/:page/?' do
  @current_page = params[:page].to_i
  if @current_page < 2
    redirect '/'
  end
  
  column_length = get_column_length(request.user_agent)
  
  view = "_design/data/_view/by_id"
  
  data_url = "#{settings.db}/#{view}?descending=true"
  
  case request.user_agent
    when /iPad|iPhone/
      @data = get_data(data_url, column_length, @current_page)
      page_length = column_length
    else
      @col1 = get_data(data_url, column_length, ((@current_page - 1) * 3) + 1)
      @col2 = get_data(data_url, column_length, ((@current_page - 1) * 3) + 2)
      @col3 = get_data(data_url, column_length, @current_page * 3)
      page_length = column_length * 3
  end
  
  @year = @params[:year]
  @year = "2010" if @year.nil? #needs to be better
  @session = get_session(@year)
  
  #get the number of records
  data = RestClient.get "#{settings.db}/_design/data/_view/count_by_year?key=%22#{@year}%22&group=true"
  rows = JSON.parse(data.body)["rows"]
  @total_records = rows[0]["value"].to_i
  @max_pages = (@total_records / page_length).ceil
  
  haml :index
end

get '/year/:year/?' do
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

get '/year/:year/:page/?' do
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
      url = "#{url}&limit=#{records_per_page.to_i()}&skip=#{records_per_page.to_i()*(current_page.to_i()-1)}"
    else
      url = "#{url}?limit=#{records_per_page.to_i()}&skip=#{records_per_page.to_i()*(current_page.to_i()-1)}"
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

  def get_column_length agent
    case agent
      when /iPad/
        6
      when /iPhone/
        4
      else
        3
    end
  end
