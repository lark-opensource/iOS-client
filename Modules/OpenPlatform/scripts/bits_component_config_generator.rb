require 'yaml'
current_pwd= Dir.pwd
project_dir = File.dirname(File.dirname(__FILE__))
Dir.chdir(project_dir)

bits_components_path = File.join(project_dir, ".bits/bits_components.yaml")

components_publish_config = {}
components = []
Dir::glob("**/*.podspec").each { |path|
    if path.include? "Pods/"
        next
    end
    name = File.basename(path, '.podspec')
    components.append(name)
    components_publish_config[name] = {"archive_source_mode"=>true,
                                       "archive_source_path"=>File.dirname(path),
                                       "archive_podspec_file"=>path}
}
config = {
    'components'=>components,
    'components_publish_config'=> components_publish_config
}

yaml_string = config.to_yaml(:Separator=>'', :Indent=>0)
puts yaml_string
File.open(bits_components_path,'w') do |f|
  f.write config.to_yaml(:Indent=>4)
end

Dir.chdir(current_pwd)
