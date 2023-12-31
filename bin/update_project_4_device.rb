#!/usr/bin/env ruby

require 'xcodeproj'
require 'pathname'

# 请先更新依赖,再执行本脚本,由于执行脚本后部分target会被删除,会导致rake pull/pod update找不到对应的target.
# 如果执行脚本后想更新,可以到podfile中删除对应的target的依赖
puts "Update project settings for device debug"

# get the specified target
scriptPath = Pathname.new(File.dirname(__FILE__)).realpath
xcproj = Xcodeproj::Project.open(scriptPath.join('../Lark.xcodeproj'))
target=xcproj.targets[0]

puts "-> Update Lark.entitlements"
# `Xcodeproj::Plist.read_from_path' works well on my device but failed on mtl devices: cannot load such file -- cfpropertylist
entitlementPath = scriptPath.join('../Lark/Supporting Files/Lark.entitlements')
entitlementHash = Xcodeproj::Plist.read_from_path(entitlementPath)
entitlementHash.clear
Xcodeproj::Plist.write_to_path(entitlementHash, entitlementPath)

puts "-> Remove Lark other target"

# 存在依赖所以执行3次
# 删除target
for i in 1..3
   # 删除target
  xcproj.targets.each do |target|
    puts target.name
    if target.name != 'Lark'
      target.remove_from_project
    end  
  end
end

# remove "Embed App Extensions"
target.build_phases.each do |phase|
  if phase.display_name == 'Embed App Extensions'
    puts "-> Remove 'Embed App Extensions'"
    phase.remove_from_project
    break
  end
end

# 清除 PROVISIONING_PROFILE.因为被工程写死
puts "-> Clear PROVISIONING_PROFILE"
xcproj.targets[0].build_configurations.each do |config|
  puts config.build_settings
  config.build_settings["PROVISIONING_PROFILE"] = ""
end

# # turn off 
# attributes = xcproj.root_object.attributes['TargetAttributes']
# attributes[target.uuid]['SystemCapabilities'].each do |capability|
#   puts "- Turn off: " + capability[0]
#   capability[1]['enabled'] = 0
# end

xcproj.save

puts "请手动设置签名"