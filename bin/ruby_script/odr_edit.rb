require 'xcodeproj'
require 'find'

script_path = File.dirname(__FILE__ )

if %x(cd #{script_path};git rev-parse --is-inside-work-tree).strip != "true"
  puts '目录非git仓库，请检查目录后重试'
  exit -1
end
project_root_path = %x(git rev-parse --show-toplevel).strip
# 遍历openplatformODR文件夹中的zip文件
openplatformODR_path = "#{project_root_path}/Lark/Resources/openplatformODR"
zip_files = []
Find.find(openplatformODR_path) do |path|
  zip_files << path if path =~ /.*\.zip$/
end

puts zip_files.to_s

# 遍历工程中所有的Lark target，并删除Copy Bundle Resources中的同名zip文件
project_path = "#{project_root_path}/Lark.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Lark' }

# 找到 Copy Bundle Resources 对应的 PBXResourcesBuildPhase
copy_bundle_phase = target.build_phases.find { |p| p.isa == 'PBXResourcesBuildPhase'}

# 打印 Copy Bundle Resources 中的文件路径
copy_bundle_phase.files.filter { | file |
  zip_files.include? file.file_ref.real_path.to_s
}.each { |file| file.remove_from_project }
project.save
