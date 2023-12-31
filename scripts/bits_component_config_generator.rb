require 'yaml'

puts "可以使用Swift命令 (swift ./scripts/Tool/Sources/Tool/main.swift), 更新更快"

current_pwd= Dir.pwd
project_dir = File.dirname(File.dirname(__FILE__))
Dir.chdir(project_dir)

bits_components_path = File.join(project_dir, ".bits/bits_components.yaml")

components_publish_config = {}
Dir::glob("**/*.podspec").each { |path|
    if path.include? "Pods/" or path.include? "Mock/" or path.include? "Example/"
        next
    end
    name = File.basename(path, '.podspec')
    components_publish_config[name] = {"archive_source_mode"=>true,
                                       "archive_source_path"=>File.dirname(path),
                                       "archive_podspec_file"=>path}
}
components_publish_config = components_publish_config.sort.to_h
config = {
  'components'=>components_publish_config.keys,
    'components_publish_config'=> components_publish_config
}

yaml_string = config.to_yaml(:Separator=>'', :Indent=>0)
File.open(bits_components_path,'w') do |f|
  f.write config.to_yaml(:Indent=>4)
end

Dir.chdir(current_pwd)
