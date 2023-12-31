# frozen_string_literal: true

module Ecosystem
  module Project
    module Assembly

      # 重新生成 Assembly.swift 内容
      #
      # @param installer [Pod::Installer]
      # @param file_path [Pathname|Void] path/to/swift_file
      def self.addUnitTestMacro(installer, file_path: nil)
        require 'cocoapods'
        require_relative '../../../bin/lib/lark-project/lib/lark/project/assembly/add_assembly'

        time = Time.now
        log 'addUnitTestMacro will change...'

        begin
          file_path ||= begin
              # 兼容旧的使用姿势，如果不传入 file_path，就去 project 中找名为 BaseAssembly.swift 的文件路径
              # @type proj [Xcodeproj::Project]
              proj = installer.aggregate_targets.first.user_project
              proj.add_assembly 'BaseAssembly.swift'
          end

          # Read the file into a string
          file = File.open(file_path)
          contents = file.read

          # Split the string into an array of lines
          lines = contents.split("\n")

          # Iterate through the lines to find the line with PrivacyAlertAssembly
          theIndex = -1
          lines.each_with_index do |line, index|
            if line.include?('let assemblies = allAssemblies()')
              # Check the previous line for #if !UNIT_TEST
              theIndex = index
            end
          end
          if theIndex != -1
              # Add the new line before the current line
              line = lines[theIndex]
              line = line.sub('let assemblies', 'var assemblies')
              lines[theIndex] = line
              # Add the #endif line after the current line
              lines.insert(theIndex + 1, """
        if OPUnitTestHelper.isUnitTest() {
            assemblies.removeAll { $0 is PrivacyAlertAssembly }
        }
""")
          end

          # Write the updated lines to the file
          File.open(file_path, 'w+') { |f| f.puts lines }

          log_ok "addUnitTestMacro succeed, spends #{Time.now - time} seconds."
        rescue => e
          # rebuild 失败不影响其他行为
          log_err "addUnitTestMacro failed, err: #{e}."
        end
      end

      def self.log(msg)
        puts "[assembly] #{msg}"
      end

      def self.log_err(msg)
        log "\e[31m#{msg}\e[0m"
      end

      def self.log_ok(msg)
        log "\e[32m#{msg}\e[0m"
      end
    end
  end
end
  