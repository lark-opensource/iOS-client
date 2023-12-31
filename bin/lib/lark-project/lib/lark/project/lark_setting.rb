# lark_setting.rb

require_relative '../tool/plist.rb'

module Lark
    module Project
      class LarkSetting
        require 'set'
        require 'pathname'
        require 'fileutils'

        LITERAL_PATTERN = '\.make\s*\(\s*userKeyLiteral\s*:\s*(.*?)\s*\)'
  
        def self.run
          literals = scan_files
          save_to_plist(literals, plist_path)
        end

        def self.ensure_auto_user_setting_keys_exists
          # 使用你之前定义的方法获取 plist 文件的路径
          plist_file_path = plist_path
      
          # 检查文件是否存在，如果不存在则创建一个空的 plist 文件
          unless File.exist?(plist_file_path)
              default_content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
                                "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" +
                                "<plist version=\"1.0\">\n" +
                                "<array>\n" +
                                "</array>\n" +
                                "</plist>"
      
              File.write(plist_file_path, default_content)
          end
        end

        def self.remove_quarantine(binary_path)
          if File.exists?(binary_path)
            system("xattr -r -d com.apple.quarantine #{binary_path}")
          end
        end
  
        def self.scan_files
          literal_set = Set.new
  
          current_file = Pathname.new(__FILE__)
          project_root = current_file.dirname
          project_root = project_root.parent while !project_root.join('Podfile').exist?

          rg_binary = project_root.join('bin/rg/bin/rg')
        
          start_time = Time.now
          remove_quarantine(rg_binary)
          output = `#{rg_binary} '#{LITERAL_PATTERN}' -g '*.swift' #{project_root}`
          end_time = Time.now
          execution_time = end_time - start_time
          puts "Execution rg UserSettingKey cost: #{execution_time} seconds"
          # Extract the literals
          output.lines.each do |line|
            match = line.match(LITERAL_PATTERN)
            if match
              if match[1].start_with?('"') && match[1].end_with?('"')
                literal_set.add(match[1][1..-2])
              else
                  raise "Error: Found a non-literal string in line: #{line.strip}, please replace into UserSettingKey.make(userKeyLiteral: staticString)"
              end
             end
           end
           literal_set
          end
  
        def self.save_to_plist(literals, path)
          literals_array = literals.to_a.sort
          Lark::Plist.save(literals_array, path)
        end
        
        # 计算 plist 文件路径的方法
        def self.plist_path
          current_file = Pathname.new(__FILE__)
          project_root = current_file.dirname
          project_root = project_root.parent while !project_root.join('Podfile').exist?
  
          # 指定子目录和文件名
          subdir = "Modules/Infra/Libs/LarkSetting/Resources/"
          filename = "AutoUserSettingKeys.plist"# 组合成完整的路径
          final_path = project_root.join(subdir, filename)
          
          # 创建子目录（如果不存在）
          FileUtils.mkdir_p(final_path.dirname)
  
          final_path.to_s
        end
      end
    end
  end