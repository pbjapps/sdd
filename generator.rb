require 'json'
require 'date'
require 'fileutils'
require 'business_time'

if ARGV.include? "generate"
  raise "generate expects another argument: year" unless ARGV.length>=2
  seed_year = ARGV[1].to_s
  # raise "generate cannot go backwards in time!" if seed_year.to_i<=2015
end

seed_file = File.read('_data/seed.json')
seed_year ||= "2015"
seed_entry = JSON.parse(seed_file)
seed = seed_entry[seed_year]
ROOT_DIR = "generated_data"

if seed.nil?
  destination_date = Date.new(seed_year.to_i,01,01)
  seed = seed_entry[seed_entry.keys.last].dup
  origin_date = Date.parse(seed["date"])
  business_days = origin_date.business_days_until(destination_date)
  seed["date"] = destination_date.to_s
  seed["id"] = seed["id"].to_i + business_days
end

seed_date = Date.parse(seed["date"])
seed_id = seed["id"]
seed_source = seed["source"]
seed_time = seed["time"]

if ARGV.include? "reset"
  raise "reset expects another argument: name of directory to reset" unless ARGV.length>=2
  year = ARGV[1].to_s
  dir_reset = "#{ROOT_DIR}/#{year}"
  FileUtils.rm_rf dir_reset
end

offset = 0
for index in 0..364
  entry = {}

  current_date = seed_date + index
  next if current_date.saturday? || current_date.sunday?
  current_id = seed_id + offset
  current_time = seed_time

  entry["date"] = current_date.to_s
  entry["id"] = current_id
  entry["time"] = current_time
  entry["source"] = seed_source.gsub "%ID", current_id.to_s
  entry["title"] = "#{current_id} Title"
  entry["passage"] = "#{current_id} Passage"
  entry["duration"] = "#{current_id} Duration"

  dir_year = current_date.year.to_s
  dir_month = current_date.strftime("%B")
  title = "#{current_date.to_s}.json"
  current_filename = "#{ROOT_DIR}/#{dir_year}/#{dir_month}/#{title}"

  FileUtils.mkdir_p(File.dirname(current_filename))
  File.open(current_filename,"w") do |f|
    f.write(JSON.pretty_generate(entry))
  end unless File.file?(current_filename)

  offset+=1
end

seed["last_generated"] = Time.now
seed_entry[seed_year] = seed
File.open("_data/seed.json","w") do |f|
  f.write(JSON.pretty_generate(seed_entry))
end
