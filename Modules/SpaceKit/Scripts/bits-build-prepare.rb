space_build_config = ARGV.first
if space_build_config == 'DEBUG_FOR_WEB'
    ENV['DEBUG_FOR_WEB'] = 'true'
    puts "设置为前端debug包"
end