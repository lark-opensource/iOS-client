# frozen_string_literal: true

require 'EEScaffold'
require 'plist'
require 'cfpropertylist'
require 'cocoapods'

module Lark
  module Project
    class Utils
      class << self
        attr_reader :current_xcode_version, :compatible_with_xcode15_and_above, :toolchains

        def compatible_with_xcode15_and_above
          return @compatible_with_xcode15_and_above unless @compatible_with_xcode15_and_above.nil?
          @compatible_with_xcode15_and_above = Pod::Version.new(EEScaffold::Swift.build.to_s) >= Pod::Version.new('5.9.0.114.6')
          @compatible_with_xcode15_and_above
        end

        def current_xcode_version
          return @current_xcode_version unless @current_xcode_version.nil?

          swift_xcode_map = {
            '5.9.2.2.56' => '15.1',
            '5.9.0.128.108' => '15.0',
            '5.8.0.124.5' => '14.3.1',
            '5.8.0.124.2' => '14.3',
            '5.7.2.135.5' => '14.2',
            '5.7.1.135.3' => '14.1',
            '5.7.0.127.4' => '14.0'
          }

          swift_version = EEScaffold::Swift.build.to_s

          @current_xcode_version = if swift_xcode_map.include?(swift_version)
                                     swift_xcode_map[swift_version]
                                   else
                                     # 未定义版本至空
                                     ''
                                   end

          @current_xcode_version
        end

        def current_xcode_toolchain_path
          return @current_xcode_toolchain_path unless @current_xcode_toolchain_path.nil?

          @current_xcode_toolchain_path = "#{EEScaffold::Xcode.xcode_path}/Toolchains/XcodeDefault.xctoolchain"
          return @current_xcode_toolchain_path if File.exist?(@current_xcode_toolchain_path)

          nil
        end

        def dancecc_toolchain_path
          @name ||= begin
            swift_command = "#{EEScaffold::Xcode.xcode_path}/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift"
            version_origin = `#{swift_command} --version 2>&-`
            matches = version_origin.match(/Apple Swift version (\d+[.\d]*)/)
            version = Pod::Version.new(matches ? matches.captures.first : '0')
            File.expand_path("~/Library/Developer/Toolchains/#{version}.xctoolchain")
          end
        end

        def restart_xcode
          xcode_paths = `pgrep -afl Xcode | grep "/Contents/MacOS/Xcode$"`.strip.split("\n").map do |line|
            line.split(' ', 2).last.split(' --args ').first.strip
          end
        
          if xcode_paths.empty?
            puts "没有找到 Xcode 进程。"
            return
          end
        
          xcode_paths.each do |path|
            puts "正在关闭 Xcode，路径：#{path}"
            system "osascript -e 'tell application \"Xcode\" to quit'"
          end
        
          sleep 5
          
          xcode_paths.each do |path|
            puts "正在打开 Xcode..."
            system "open -a '#{path}'"
          end
        end

        def toolchains
          if @toolchains.nil?
            toolchains_dir = File.expand_path('~/Library/Developer/Toolchains')
            toolchains_info = {}

            Dir["#{toolchains_dir}/*.xctoolchain/Info.plist"].each do |file|
              cfplist = CFPropertyList::List.new(file: file)
              plist = CFPropertyList.native_types(cfplist.value)
              toolchain_name = File.basename(File.dirname(file))
              bundle_id = plist['CFBundleIdentifier']
              short_display_name = plist['ShortDisplayName']
              toolchains_info[toolchain_name] = { 'bundle_id' => bundle_id, 'short_display_name' => short_display_name }
            end
            @toolchains = toolchains_info
          end
          @toolchains
        end

        def current_toolchain_bundle_id
          toolchain_bundle_id = `defaults read com.apple.dt.Xcode DVTDefaultToolchainOverrideIdentifer`
          toolchain_bundle_id.strip
        end
        
        def set_current_toolchain(bundle_id)
          system "defaults write com.apple.dt.Xcode DVTDefaultToolchainOverrideIdentifer -string '#{bundle_id}'"
        end

        def reset_current_toolchain
          system "defaults delete com.apple.dt.Xcode DVTDefaultToolchainOverrideIdentifer"
        end

      end
    end
  end
end
