require 'rake'

require 'rubygems'
require 'yaml'
require 'rest_client'
require 'json'

SITE =  "http://localhost"
PORT = "5984"
DATABASE = "deposits"

desc "script data"
task :script_data do
  if ENV['RACK_ENV'] && ENV['RACK_ENV'] == 'production'
    db = ENV['COUCH_URL']
  else
    conf = YAML.load(File.read('config/virtualserver/config.yml'))
    db = conf[:couch_url]
  end
  
  view = "_design/data/_view/by_id"
  data_url = "#{db}/#{view}?descending=true"
  data = RestClient.get "#{data_url}"
  rows = JSON.parse(data.body)["rows"]
  
  path = ""
  
  unless File.exists?("db/_docs")
    Dir.mkdir("db/_docs")
  end
  rows.each do |rec|
    unless File.exists?("db/_docs/#{rec["id"]}.json")
      output = File.open("db/_docs/#{rec["id"]}.json", 'a')
      output.write("{\n")
      rec["value"].each do |value|
        if value[0] != "_id" and value[0] != "_rev"
          output.write("  \"#{value[0]}\" : ")
          if value[1].class == String
            output.write("\"#{value[1]}\"\n")
          else
            output.write("#{value[1]}\n")
          end
        end
      end
      output.write("}")
      output.close
    end
  end
end