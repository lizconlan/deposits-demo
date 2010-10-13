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
      doc = "{\n"
      rec["value"].each do |value|
        if value[0] != "_id" and value[0] != "_rev"
          doc = "#{doc}  \"#{value[0]}\" : "
          doc = process_data_values(value[1], doc)
        end
      end
      doc = "#{doc}}"
      doc.gsub!(",\n}", "\n}")
      File.open("db/_docs/#{rec["id"]}.json", 'a') { |f| f.write(doc) }
    end
  end
end

def process_data_values value, doc, suppress_line_break=false
  if value.class == String
    doc = "#{doc}\"#{value.gsub(/"/, '\"')}\","
    unless suppress_line_break
      doc = "#{doc}\n"
    end
  elsif value.class == Array
    doc = "#{doc}["
    value.each do |elem|
      doc = process_data_values(elem, doc, true)
    end
    doc = "#{doc}],\n"
    doc.gsub!(",]", "]")
  else
    doc = "#{doc}#{value},\n"
  end
  doc
end