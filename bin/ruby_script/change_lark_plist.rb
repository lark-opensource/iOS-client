require 'find'
require 'json'
require 'Plist'

$ios_client_path = ENV['TARGETCODEPATH']

def read_info_json(path)
  json_str = File.read(path)
  json_dict = JSON.parse(json_str)
  return json_dict
end

def replace_plist_strings(lark_path, key, new_value, file_name)
  # 遍历指定路径下的所有InfoPlist.strings文件
  Find.find(lark_path) do |path|
    if path =~ /\/InfoPlist\.strings$/ && path.include?(file_name)
      file_content = File.read(path)
      if file_content.include? "\"#{key}\""
        # 使用正则表达式匹配key和value，替换value为指定值
        file_content.gsub!(/("#{key}"\s*=\s*").*(";)/, "\\1#{new_value}\\2")
        # 将替换后的内容写回到.strings文件中
        File.write(path, file_content)
      else
        File.open(path, 'a+') do |f|
          if !file_content.end_with?("\n")
            f.puts "\n"
          end
          f.puts "\"#{key}\" = \"#{new_value}\";"
        end
      end
    end
  end
end

# 搜索路径
lark_path = $ios_client_path + '/Lark'
info_plist_path = $ios_client_path + '/Lark/Info.plist'
plist = Plist.parse_xml(info_plist_path)
# lark_plist.json为各个语言需要替换的k-v json文件，路径在iOS-client/Lark目录下
json_path = $ios_client_path + '/Lark/lark_plist.json'
json = read_info_json(json_path)
json.keys.each do |key|
    json[key].keys.each do |inner_key|
        new_value = json[key][inner_key]
        replace_plist_strings(lark_path, inner_key, new_value, key)
        if key == "Base.lproj"
            plist[inner_key] = new_value
            File.write(info_plist_path, Plist::Emit.dump(plist))
        end
    end
end
