require 'optparse'

class Arg
  attr_accessor :name, :targets, :dynamic

  def initialize(name, targets, dynamic)
    @name = name
    @targets = targets
    @dynamic = dynamic
  end
end

args = []
current_name = nil
current_targets = nil
current_dynamic = nil
output = "BUILD"

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-n", "--spec_name NAME", "Spec name") do |v|
    if current_name
      args << Arg.new(current_name, current_targets, current_dynamic)
    end

    current_name = v
    current_targets = nil
    current_dynamic = nil
  end

  opts.on("-t", "--spec_targets a,b,c", Array, "Spec targets") do |v|
    current_targets = v
  end

  opts.on("-d", "--[no-]dynamic", "Dynamic") do |v|
    current_dynamic = v
  end

  opts.on("-o", "--ouput OUTPUT", Array, "ouput") do |v|
    ouput = v
  end
end.parse!

# Add the last spec
if current_name
  args << Arg.new(current_name, current_targets, current_dynamic)
end

build_content = <<-END
load("@build_bazel_rules_bitsky//rules:module_framework.bzl", "bitsky_library")
load("@build_bazel_rules_bitsky//rules:resources.bzl", "resource_bundle", "resource_group")
load("xcconfig.bzl", "xcconfigs")

END

arg = args[0]
spec_name = arg.name
spec_targets = arg.targets
spec_dynamic = arg.dynamic

build_content += <<-END
filegroup(
  name = "MMKVCore_hdrs",
  srcs = glob([
    "Core/MMBuffer.h",
    "Core/MMKV.h",
    "Core/MMKVLog.h",
    "Core/MMKVPredef.h",
    "Core/PBUtility.h",
    "Core/ScopedLock.hpp",
    "Core/ThreadLock.h",
    "Core/aes/openssl/openssl_md5.h",
    "Core/aes/openssl/openssl_opensslconf.h",
  ]),  
)

all_sources = [
    "Core/*",
    "Core/*.h",
    "Core/*.cpp",
    "Core/*.hpp",
    "Core/aes/*",
    "Core/aes/openssl/*",
    "Core/crc32/*.h",
  ]

all_assembly_sources = [
    "Core/aes/openssl/*.S",
  ]

arc_sources = ['Core/MemoryFile.cpp', 
          'Core/ThreadLock.cpp', 
          'Core/InterProcessLock.cpp', 
          'Core/MMKVLog.cpp',
          'Core/PBUtility.cpp', 
          'Core/MemoryFile_OSX.cpp', 
          'Core/aes/openssl/openssl_cfb128.cpp', 
          'Core/aes/openssl/openssl_aes_core.cpp', 
          'Core/aes/openssl/openssl_md5_one.cpp', 
          'Core/aes/openssl/openssl_md5_dgst.cpp', 
          'Core/aes/AESCrypt.cpp']

filegroup(
  name = "MMKVCore_arc_srcs",
  srcs = glob(arc_sources, exclude = all_assembly_sources)
)

filegroup(
  name = "MMKVCore_non_arc_srcs",
  srcs = glob(all_sources, exclude = arc_sources + all_assembly_sources),  
)

filegroup(
  name = "MMKVCore_assembly_srcs",
  srcs = glob(all_assembly_sources),  
)

objc_library(
  name = "MMKVCore_assembly",  
  hdrs = glob(["Core/**/*.h"]),
  srcs = [":MMKVCore_assembly_srcs"],
  copts = ["-x assembler-with-cpp",],
)

            END

shortest_target = spec_targets.min_by { |s| s.length }
other_targets = spec_targets.reject { |s| s == shortest_target }
temp_targets = spec_dynamic ? [shortest_target] : spec_targets
        
temp_targets.each do |temp_target|
    build_content += <<-END

bitsky_library(
  name = "#{temp_target}_MMKVCore_non_arc",
  module_name = "MMKVCore",
  public_hdrs = [":MMKVCore_hdrs"],
  srcs = [":MMKVCore_non_arc_srcs"],
  copts = ["-std=gnu++17", "-stdlib=libc++", "-x objective-c++", "-fno-objc-arc"],
  sdk_frameworks = ["CoreFoundation", "UIKit"],
  libraries = ["z", "c++",],  
  rules_ios = True,
  xcconfig_by_build_setting = xcconfigs["MMKVCore"],  
  deps = [":MMKVCore_assembly"]
)

bitsky_library(
  name = "#{temp_target}_MMKVCore",
  module_name = "MMKVCore",
  public_hdrs = [":MMKVCore_hdrs"],
  srcs = [":MMKVCore_arc_srcs"],
  copts = ["-std=gnu++17", "-stdlib=libc++", "-x objective-c++"],
  sdk_frameworks = ["CoreFoundation", "UIKit"],
  libraries = ["z", "c++",],  
  rules_ios = True,
  xcconfig_by_build_setting = xcconfigs["MMKVCore"],  
  link_dynamic = True,
  deps = [":#{temp_target}_MMKVCore_non_arc"],
  visibility = ["//visibility:public"]
)

            END
end 

if spec_dynamic   
    other_targets.each do |extension|
      str = <<-END
alias(
  name = "#{extension}_MMKVCore",
  actual = ":#{shortest_target}_MMKVCore",
  visibility = ["//visibility:public"],
)

      END
    build_content += str
    end            
end


Dir.chdir File.dirname(__FILE__) do
  File.open(output, "w") do |file|
    file.puts build_content
  end
end