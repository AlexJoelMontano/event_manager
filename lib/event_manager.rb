require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def add_parenthesis(phone)
  parenthesis_1 = phone.insert(0,'(')

  parenthesis_2 = parenthesis_1.insert(4,')')

  phone = parenthesis_2[0..13]
end

def parenthesis_phones(phone)
  if phone[0].include?('1')
    phone = phone[1..12]
  else
    phone
  end

  check_phone = phone.to_s

  if check_phone[0].include?('(') and check_phone[4].include?(')')
    check_phone[0..13]
  elsif check_phone.include?('-')
    check_phone.delete! '-'

    parenthesis = add_parenthesis(check_phone)

  elsif check_phone.include?('.')
    check_phone.delete! '.'

    parenthesis = add_parenthesis(check_phone)

  else
    parenthesis = add_parenthesis(check_phone)
  end
end

def array_phones(phones)
  if phones[5].include?(' ') and phones[9].include?(' ')
    phones
  elsif phones[5].include?(' ')
    phones = phones.insert(9,' ')
  else
    phones = phones.insert(5, ' ')
    phones = phones.insert(9,' ')
  end

  array_phones = phones.split(' ')
end

def clean_phones(phone)
  area_code = phone[0]
  three_dig = phone[1].to_i
  last_four = phone[2].split('')

  if last_four[0].include?('-')
    last = last_four[1..4].join().to_i
  else
    last = last_four.join()
  end

  if three_dig.to_s.length < 3 || last.to_s.length < 3
    phone = nil
  else
    phone = area_code,three_dig.to_s,last.to_s
  end

end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts ' '
puts '---------------------------- '
puts ' Event Manager initialized. '
puts '---------------------------- '
puts ' '
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  first_name = row[:first_name]

  last_name = row[:last_name]

  phone = clean_phones(array_phones(parenthesis_phones(row[:phone])))

  id = row[0]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

  print '.'
end

puts ' '
puts ' '
puts '-----------------------'
puts 'file creation complete.'
puts "-----------------------"
