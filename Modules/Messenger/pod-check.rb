#!/usr/bin/env ruby
# need EEScaffold version >= 0.1.156

result = `pod dependency-to-json Lark #{ARGV[0]} > /dev/null 2>&1; jq '.[0].all_dependencies[].name' dependency.json|grep #{ARGV[1]}`
if result.length > 0
  puts "YES, #{ARGV[0]} has dependency: #{ARGV[1]}"
else
  puts "NO,  #{ARGV[0]} does not depend on #{ARGV[1]}"
end
