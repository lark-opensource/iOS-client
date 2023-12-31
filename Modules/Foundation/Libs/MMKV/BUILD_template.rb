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

args.each do |arg|
    spec_name = arg.name
    spec_targets = arg.targets
    spec_dynamic = arg.dynamic

    if spec_name.end_with? "MMKV.podspec"
        spec_targets.each do |target|
            build_content += <<-END
bitsky_library(
  name = "#{target}_MMKV",
  module_name = "MMKV",
  public_hdrs = ["iOS/MMKV/MMKV/MMKV.h", "iOS/MMKV/MMKV/MMKVHandler.h"],
  srcs = glob([
              "iOS/MMKV/MMKV/*",
              "iOS/MMKV/MMKV/*.h",
              "iOS/MMKV/MMKV/*.mm",
              "iOS/MMKV/MMKV/*.hpp",
              ]),
  copts = ["-std=gnu++17", "-stdlib=libc++", "-x objective-c++", "-fno-objc-arc"],
  sdk_frameworks = ["CoreFoundation", "UIKit"],
  libraries = ["z", "c++",],
  rules_ios = True,
  xcconfig_by_build_setting = xcconfigs["MMKV"],
  pod_deps = ["MMKVCore"],
  visibility = ["//visibility:public"],
)

            END
          end
    end
    if spec_name.end_with? "MMKVAppExtension.podspec"
        shortest_target = spec_targets.min_by { |s| s.length }
        other_targets = spec_targets.reject { |s| s == shortest_target }
        temp_targets = spec_dynamic ? [shortest_target] : spec_targets
        
        temp_targets.each do |temp_target|
            build_content += <<-END
bitsky_library(
  name = "#{temp_target}_MMKVAppExtension",
  module_name = "MMKVAppExtension",
  public_hdrs = ["iOS/MMKV/MMKV/MMKV.h", "iOS/MMKV/MMKV/MMKVHandler.h"],
  srcs = glob([
  "iOS/MMKV/MMKV/*",
  "iOS/MMKV/MMKV/*.h",
  "iOS/MMKV/MMKV/*.mm",
  "iOS/MMKV/MMKV/*.hpp",
  ]),
  copts = ["-std=gnu++17", "-x objective-c++", "-fno-objc-arc"],
  sdk_frameworks = ["CoreFoundation", "UIKit"],
  libraries = ["z", "c++",],  
  rules_ios = True,
  xcconfig_by_build_setting = xcconfigs["MMKVAppExtension"],
  link_dynamic = #{spec_dynamic ? "True" : "False"},
  pod_deps = ["MMKVCore"],
  visibility = ["//visibility:public"],
)

            END
        end 

        if spec_dynamic   
            other_targets.each do |extension|
                str = <<-END
alias(
  name = "#{extension}_MMKVAppExtension",
  actual = ":#{shortest_target}_MMKVAppExtension",
  visibility = ["//visibility:public"],
)

                END
            build_content += str
            end            
        end
    end
end


Dir.chdir File.dirname(__FILE__) do
  File.open(output, "w") do |file|
    file.puts build_content
  end
end