require 'yaml'
require 'pathname'
require 'find'
require 'fileutils'
require 'json'

current_dir_path = Pathname.new(File.dirname(__FILE__))
project_dir = File.expand_path(current_dir_path + '../..')
output_path = project_dir + '/bin/ka_resource_replace/output'
assets_dir = "#{output_path}/Assets.xcassets"
support_ratio = '3x'
dark_dir_name = 'dark.theme'
yaml = YAML.safe_load(File.open(current_dir_path + 'static_config.yaml'))
config = yaml['keys']

if yaml['darkmode_support'].to_s == 'true'
    static_images = config['image'].flat_map { |res| res.values }.select { |res| res['local_des_path'] != nil }.map { |res| res['alias'] }
    static_images.each { |image|
        begin
            Find.find("#{assets_dir}/#{dark_dir_name}/#{image}.imageset")
            .select { |path| path.include?(support_ratio) }
            .each { |path| FileUtils.mv(path, path.sub("#{dark_dir_name}/", '').sub(image + "@#{support_ratio}", image + '_dark' + "@#{support_ratio}")) }
            
            content_json = {
                'images': [],
                'info': {
                    'author': 'xcode',
                    'version': 1
                }
            }
            info = {
                'idiom': 'universal',
                'scale': ''
            }
            dark_info = {
                'appearances': [
                {
                    'appearance': 'luminosity',
                    'value': 'dark'
                }
                ],
                'idiom': 'universal',
                'scale': ''
            }
            
            image_name = Find.find("#{assets_dir}/#{image}.imageset").select { |path| path.include?(support_ratio) }.first.split('/')[-1]
            for i in 1..3
                current_ratio = "#{i}x"
                
                current_info = info.dup
                current_info[:scale] = current_ratio
                current_dark_info = dark_info.dup
                current_dark_info[:scale] = current_ratio
                if current_ratio == support_ratio
                    current_info[:filename] = image_name
                    current_dark_info[:filename] = image_name.sub(image, image + '_dark')
                end
                content_json[:images] += [current_info]
                content_json[:images] += [current_dark_info]
            end
            
            content_json_path = Find.find("#{assets_dir}/#{image}.imageset").select { |path| path.include?('Contents.json') }.first
            File.write(content_json_path, JSON.dump(content_json))
        rescue Errno::ENOENT => e
            puts "process #{assets_dir}/#{dark_dir_name}/#{image}.imageset ENOENT error: #{e}"
        rescue StandardError => e
            puts "process #{assets_dir}/#{dark_dir_name}/#{image}.imageset StandardError error: #{e}"
        end
    }
end

config
.flat_map { |_, materials| materials.map { |material| material.values.first['local_des_path'] } }
.compact!
.map { |paths| ["#{output_path}/" + paths.split(',')[0] + '/', project_dir + '/' + paths.split(',')[1]] }
.each { |paths| File.exists?(paths[0]) ? `rsync -a --del #{paths[0]} #{paths[1]}` : (p "Warning: Miss dir #{paths[0]}") }
