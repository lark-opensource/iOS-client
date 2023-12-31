require 'json'

json_string = ARGV[0]
result = JSON.parse(json_string)

puts result[ARGV[1]]
