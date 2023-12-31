# 检查是否已经导出过 PATH
if ENV['PATH'].to_s.include?("#{ENV['HOME']}/Library/Caches/BitSky/tools/skyup/stable")
    puts "PATH already exported"
else
    ENV['PATH'] = "#{ENV['HOME']}/Library/Caches/BitSky/tools/skyup/stable:#{ENV['PATH']}"
    raise "install skyup failed" unless system('curl -fsSL --retry 3 http://tosv.byted.org/obj/bit-io/bitsky/scripts/skyup_install.sh | bash')
end
  
