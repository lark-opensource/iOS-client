require 'yaml'
require 'pathname'


module KAResource
    class ReplaceI18N
      
      def initialize()
      end

      def run!
        begin
            current_dir_path = Pathname.new(File.dirname(__FILE__))
            project_dir = File.expand_path(current_dir_path + '../..')
            
            output_path = project_dir + '/bin/ka_resource_replace/output'
            yaml = YAML.safe_load(File.open(current_dir_path + 'static_config.yaml'))
            config = yaml['keys']
            puts "-- start replace_ka_static_i18n --"
            # 提取所有包含'static'的alias_keys
            alias_keys = config['text'].select { |item| item.values.first['scenes'].include?('static') }.map { |item| item.values.first['alias'] }

            # 如果没有包含'static'的文案，则不执行后续操作
            if alias_keys.empty?
                puts "replace_ka_static_i18n No text replacements needed."
                return
            end
            puts "replace_ka_static_i18n alias_keys: #{alias_keys}"

            # 2. 从dynamic_resource.bundle读取所有语言的文案并存储
            translations = {}
            Dir.glob("#{output_path}/*.lproj/*.strings") do |dynamic_file|
              # 获取父目录名作为语言键
              language_dir = File.basename(File.dirname(dynamic_file))
              language_key = language_dir.sub('.lproj', '').gsub("_", "-")
              translations[language_key] ||= {}
            
              File.foreach(dynamic_file) do |line|
                if line =~ /"(\w+)"\s*=\s*"(.*?)";/
                  hash_value, text = $1, $2
                  translations[language_key][hash_value] = text
                end
              end
            end            

            puts "replace_ka_static_i18n loaded ka i18n successfully. #{translations}"

            # 3. 使用Dir.glob寻找要替换的文件并创建alias到hash的映射 *.strings{,dict}
            Dir.glob("#{project_dir}/**/auto_resources/*.strings") do |strings_file|
                pod_path = File.dirname(File.dirname(strings_file))

                # 寻找与Bundlei18n.swift匹配的文件路径
                bundlei18n_files = Dir.glob(File.join(pod_path, '**/Bundlei18n.swift'))
                next if bundlei18n_files.empty?

                bundlei18n_path = bundlei18n_files.first

                # 创建alias到hash的映射
                alias_to_hash = {}
                meta_content = File.read(bundlei18n_path)
                alias_keys.each do |alias_key|
                    if hash_match = meta_content.match(/"#{alias_key}":\s*{\s*"hash":\s*"(\w+)"/)
                        alias_to_hash[alias_key] = hash_match[1]
                    end
                end
                next if alias_to_hash.empty?

                puts "ka repalce static i18n Processing pod: #{strings_file} start, keys_to_hash: #{alias_to_hash}"

                # 4. 使用映射来替换auto_resources中的文案
                language_key = File.basename(strings_file, '.strings')
                strings_content = File.read(strings_file)

                alias_to_hash.each do |alias_key, hash_value|
                    if translations[language_key] && (new_text = translations[language_key][alias_key])
                        puts "replace language_key: #{language_key}, alias_key: #{alias_key}, strings_file #{strings_file}"
                        strings_content.gsub!(/"#{hash_value}"\s*=\s*".*?";/, "\"#{hash_value}\" = \"#{new_text}\";")
                    elsif translations["en-US"] && (new_text = translations["en-US"][alias_key])
                        # 5. 使用en-US兜底
                        puts "replace language_key: by en-US, alias_key: #{alias_key}, strings_file #{strings_file}"
                        strings_content.gsub!(/"#{hash_value}"\s*=\s*".*?";/, "\"#{hash_value}\" = \"#{new_text}\";")
                    end
                end

                File.write(strings_file, strings_content)
            end

            rescue StandardError => e
                puts "replace_ka_static_i18n error occurred: #{e.message}"
            end
        end
    end
end