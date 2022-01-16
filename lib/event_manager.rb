# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  # if the zip code is exactly five digits, assume that it is ok
  # if the zip code is more than five digits, truncat it to the first five digits
  # if the zip code is less than five digits, add zeros tot he front until it becomes five digits

  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  number = number.gsub(/[.\sA-Z\-()+]/, '')
  if number.length == 11 && number[0] == '1'
    number[1..-1]
  elsif number.length == 10
    number
  else
    'Valid number not given'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = []
days = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  number = clean_phone_number(row[:homephone])

  regdate = row[:regdate]
  date = DateTime.strptime(regdate, '%m/%d/%Y %H:%M').to_time
  hours << date.strftime('%I %p')
  days << date.wday

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

def count_hours(hours)
  hours.reduce(Hash.new(0)) do |count, hour|
    count[hour] += 1
    count
  end
end

def count_days(name_days)
  name_days.reduce(Hash.new(0)) do |days_count, num|
    days_count[num] += 1
    days_count
  end
end

def peak_registration_hours(hours)
  count = count_hours(hours)
  count.each do |k, v|
    puts "The best time to advertise is #{k}" if v == count.values.max
  end
end

def get_name_days(days)
  days.map do |day_num|
    case day_num
    when 0
      "Sunday"
    when 1
      "Monday"
    when 2
      "Tuesday"
    when 3
      "Wednesday"
    when 4
      "Thursday"
    when 5
      "Friday"
    when 6
      "Saturday"
    end
  end
end

def most_common_day(name_days)
  days_count = count_days(name_days)
  days_count.each do |k, v|
    puts "The most common registration day is #{k}" if v == days_count.values.max
  end
end

peak_registration_hours(hours)
most_common_day(get_name_days(days))
