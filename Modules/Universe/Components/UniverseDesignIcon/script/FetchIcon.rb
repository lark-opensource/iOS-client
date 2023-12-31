require "erb"
require "pathname"
require "csv"
require "set"
require "json"
require "fileutils"
require "open3"
require 'thread'
require 'optparse'

# DownLoad Icon From https://bnpm.byted.org/@universe-ui
def download_and_process_icon_resources(version)
  download_resource_package(version)

  # 检查资源完整性
  check_resource_integrity()
  check_resource_validity()

  # 删除iOS不需要的icon
  delete_pa_begining_icons()
  delete_block_list_icons()
  delete_deprecated_icons()

  # 兼容名字不一样问题
  `cp  ./package/icons/icon_call-massage_outlined.svg ./package/icons/icon_call-message_outlined.svg `
end

def generate_icon_resources(version, enable_pdf)
  # 生成 IconFont 资源
  generate_icon_font_file()
  # 生成 Assets 资源
  generate_image_assets(enable_pdf)
end

# 转换为代码中的变量名，移除 icon 前缀，转换为驼峰命名
def convert_to_lower_camel_style(file_name)
  name = file_name.delete_prefix("icon_")
  name.gsub!(/-|_/, "_")
  name.gsub(/\.svg$/, "")
  name = name.split("_").map(&:capitalize).join
  name[0] = name[0].downcase
  name
end

# 文件名、代码中变量名、icon 尺寸 (单位 pt)
def create_png_image_asset(file_name, name, size_in_pt, useInkscape)
  has_dm = File.exist?("./temp/imageset_icons/#{file_name}-dm.svg")
  size_2x = size_in_pt * 2
  size_3x = size_in_pt * 3

  puts "  - convert #{file_name}, name: #{name}, size: #{size_in_pt}, darkmode: #{has_dm}"

  if File.directory?("./#{name}.imageset")
    FileUtils.rm_rf("./#{name}.imageset")
  end

  FileUtils.mkdir("./#{name}.imageset")

  if useInkscape
    # 使用 inkscape 创建 png
    system("inkscape ./temp/imageset_icons/#{file_name}.svg --export-width #{size_2x} --export-height #{size_2x} -o ./#{name}.imageset/#{name}@2x.png")
    system("inkscape ./temp/imageset_icons/#{file_name}.svg --export-width #{size_3x} --export-height #{size_3x} -o ./#{name}.imageset/#{name}@3x.png")
    if has_dm
      system("inkscape ./temp/imageset_icons/#{file_name}.svg --export-width #{size_2x} --export-height #{size_2x} -o ./#{name}.imageset/#{name}-dm@2x.png")
      system("inkscape ./temp/imageset_icons/#{file_name}.svg --export-width #{size_3x} --export-height #{size_3x} -o ./#{name}.imageset/#{name}-dm@3x.png")
    end
  else
    # 使用 cairosvg 创建 png
    system("cairosvg ./temp/imageset_icons/#{file_name}.svg --output-width #{size_2x} --output-height #{size_2x} -o ./#{name}.imageset/#{name}@2x.png")
    system("cairosvg ./temp/imageset_icons/#{file_name}.svg --output-width #{size_3x} --output-height #{size_3x} -o ./#{name}.imageset/#{name}@3x.png")
    if has_dm
      system("cairosvg ./temp/imageset_icons/#{file_name}-dm.svg --output-width #{size_2x} --output-height #{size_2x} -o ./#{name}.imageset/#{name}-dm@2x.png")
      system("cairosvg ./temp/imageset_icons/#{file_name}-dm.svg --output-width #{size_3x} --output-height #{size_3x} -o ./#{name}.imageset/#{name}-dm@3x.png")
    end
  end

  json_template_file = has_dm ? "templates/Contents.json.dm.erb" : "templates/Contents.json.erb"
  json_template = File.read(json_template_file)

  b = binding
  b.local_variable_set(:filename, name)
  json = ERB.new(json_template, 0, "%<>")
  File.write("./#{name}.imageset/Contents.json", json.result(b))

  if File.directory?("../resources/Assets.xcassets/#{name}.imageset")
    FileUtils.rm_rf("../resources/Assets.xcassets/#{name}.imageset")
  end

  FileUtils.mv("./#{name}.imageset", "../resources/Assets.xcassets/")
end

# 文件名、代码中变量名、icon 尺寸 (单位 pt)
def create_pdf_image_asset(file_name, name, size_in_pt)
  has_dm = File.exist?("./temp/imageset_icons/#{file_name}-dm.svg")
  size_2x = size_in_pt * 2
  size_3x = size_in_pt * 3

  # puts "  - convert #{file_name}, name: #{name}, size: #{size_in_pt}, darkmode: #{has_dm}"

  if File.directory?("./#{name}.imageset")
    FileUtils.rm_rf("./#{name}.imageset")
  end

  FileUtils.mkdir("./#{name}.imageset")

  system("cairosvg ./temp/imageset_icons/#{file_name}.svg -o ./#{name}.imageset/#{name}.pdf")
  # system("inkscape ./temp/imageset_icons/#{file_name}.svg --export-pdf=./#{name}.imageset/#{name}.pdf --export-text-to-path --export-pdf-version=1.4")
  if has_dm
    system("cairosvg ./temp/imageset_icons/#{file_name}-dm.svg -o ./#{name}.imageset/#{name}-dm.pdf")
    # system("inkscape ./temp/imageset_icons/#{file_name}-dm.svg --export-pdf=./#{name}.imageset/#{name}-dm.pdf --export-text-to-path --export-pdf-version=1.4")
  end

  json_template_file = has_dm ? "templates/Contents_pdf.json.dm.erb" : "templates/Contents_pdf.json.erb"
  json_template = File.read(json_template_file)

  b = binding
  b.local_variable_set(:filename, name)
  json = ERB.new(json_template, 0, "%<>")
  File.write("./#{name}.imageset/Contents.json", json.result(b))

  if File.directory?("../resources/Assets.xcassets/#{name}.imageset")
    FileUtils.rm_rf("../resources/Assets.xcassets/#{name}.imageset")
  end

  FileUtils.mv("./#{name}.imageset", "../resources/Assets.xcassets/")
end

def generate_swift_files(version)

  # Read resource list
  iconNameMapJSON = File.read("./temp/iconNameMap.json")
  resourceNameMap = JSON.parse(iconNameMapJSON)

  figmaNameMapJSON = File.read("./temp/iconTypeToFigmaNameMap.json")
  iconTypeToFigmaNameMap = JSON.parse(figmaNameMapJSON)

  # Read deprecated icon configuration
  replacement = File.read("./package/replacement.json")
  deprecated_list = JSON.parse(replacement)

  deprecated_hash = {}
  deprecated_list.each do |key, value|
    depIcon = convert_to_lower_camel_style(key)
    newIcon = convert_to_lower_camel_style(value["newIcon"])
    if resourceNameMap.key?(newIcon)
      deprecated_hash[depIcon] = newIcon
    end
  end

  # Set up template data
  b = binding
  b.local_variable_set(:iconNameHash, resourceNameMap)
  b.local_variable_set(:figmaNameMap, iconTypeToFigmaNameMap)
  b.local_variable_set(:deprecatedIconHash, deprecated_hash)
  b.local_variable_set(:version, version)

  # Write the Swift code with templates
  iconTypeTemplate = File.read("templates/UDIconType.swift.erb")
  iconType = ERB.new(iconTypeTemplate, 0, "%<>")
  iconTypeFile = File.new("../src/UDIconType.swift", "w")
  iconTypeFile.puts iconType.result(b)
  iconTypeFile.close

  iconTemplate = File.read("templates/UDIcon+Icon.swift.erb")
  icon = ERB.new(iconTemplate, 0, "%<>")
  iconFile = File.new("../src/UDIcon+Icon.swift", "w")
  iconFile.puts icon.result(b)
  iconFile.close

  iconResourceTemplate = File.read("templates/UDIconType+Resource.swift.erb")
  iconResource = ERB.new(iconResourceTemplate, 0, "%<>")
  iconResourceFile = File.new("../src/UDIconType+Resource.swift", "w")
  iconResourceFile.puts iconResource.result(b)
  iconResourceFile.close
end

def check_icon_font_generator_installation()
  puts "\n🔍 Checking icon font tools..."
  if not File.exist?("/usr/local/bin/icon-font-generator")
    puts "- Install icon font tools..."
    `npm install -g icon-font-generator`
  else
    puts "  - Exist icon font tools..."
  end
end

def check_cairo_svg_installation()
  puts "\n🔍 Checking png tools..."
  if not File.exist?("/opt/homebrew/bin/cairosvg")
    puts "  - Install png tools..."
    `brew install cairo`
    `pip3 install cairosvg`
  else
    puts "  - Exist png tools..."
  end
  # 如果出现 cairosvg command not found 请检查是否配置了相关python环境
end

def clean_temporary_files()
  puts "\n🧹 Cleaning resource folder..."
  `rm -rf iconfontsvg.json`
  `rm -rf ./package`
  `rm -rf ./temp`
end

def clean_previous_version_resources()
  puts "\n🧹 Cleaning resource folder..."
  # 删除 Assets 文件夹的内容
  `rm -rf ../resources/Assets.xcassets/*`
  # 删除旧 ttf 文件
  `rm -f ../resources/UniverseDesignIconFont.ttf`
  # 删除 IconFont 产物
  `rm -rf ../iconfont_output`
end

def download_resource_package(version)
  puts "\n📥 Downloading resource package..."
  `curl https://bnpm.byted.org/@universe-design/icons/download/@universe-design/icons-#{version}.tgz --output icon.tgz`
  `tar xzf icon.tgz`
  `rm -rf icon.tgz`
end

def delete_pa_begining_icons()
  puts "\n🗑 Ready to remove files begining with 'pa'..."
  icon_dir = "./package/icons"
  white_list = CSV.read("icon_pa_white_list.csv").map(&:first)
  all_icons = Dir.children(icon_dir).map { |file| File.basename(file, ".*") }
  for icon_name in all_icons
    if white_list.include?(icon_name)
      puts "  - skip removing #{icon_name} for white list"
      next
    end
    if icon_name.start_with?("icon_pa-")
      svg_path = File.join(icon_dir, "#{icon_name}.svg")
      dm_path = File.join(icon_dir, "#{icon_name}-dm.svg")
      if File.exist?(svg_path)
        File.delete(svg_path)
      end
      if File.exist?(dm_path)
        File.delete(dm_path)
      end
      puts "  - removing #{icon_name}"
    end
  end
end

def delete_block_list_icons()
  puts "\n🗑 Ready to remove files in block list..."
  # 读取正常的黑名单图标，在转换为 png 前移除相关文件
  icon_dir = "./package/icons"
  CSV.foreach("icon_block_list.csv", col_sep: "\t") do |row|
    icon_name = row[0]
    svg_path = File.join(icon_dir, "#{icon_name}.svg")
    dm_path = File.join(icon_dir, "#{icon_name}-dm.svg")
    if File.exist?(svg_path)
      File.delete(svg_path)
    end
    if File.exist?(dm_path)
      File.delete(dm_path)
    end
    puts "  - removing #{icon_name}"
  end
end

def delete_deprecated_icons()
  puts "\n🗑 Ready to remove files in deprecation list..."
  icon_dir = "./package/icons"
  replacement = File.read("./package/replacement.json")
  deprecated_list = JSON.parse(replacement)
  deprecated_list.keys.each do |icon_name|
    svg_path = File.join(icon_dir, "#{icon_name}.svg")
    dm_path = File.join(icon_dir, "#{icon_name}-dm.svg")
    if File.exist?(svg_path)
      File.delete(svg_path)
    end
    if File.exist?(dm_path)
      File.delete(dm_path)
    end
    puts "  - removing #{icon_name}"
  end
end

def generate_icon_font_file()
  puts "\n📋 Generating IconFont File..."

  `python3 ./iconFontSvgInfo.py` # 将能够生成 iconfont 的图标过滤出来，写入 iconfontsvg.json

  # 读取需要特定 size 的 icon. key: 转换后的名称，value: 大小
  iconSizeMap = Hash.new
  iconSizeMap.default = 32
  CSV.foreach("icon_special_sizes.csv", :col_sep => "\t") do |row|
    iconSizeMap[row[0]] = row[1].to_i
  end
  #
  json = File.read("iconfontsvg.json")
  icon_font_candidates = JSON.parse(json)
  # 将需要转换成 IconFont 的文件移动到 ./temp/iconfont_icons 文件夹
  `mkdir -p ./temp/iconfont_icons`
  puts "  - Preparing icon font files..."
  ignore_list = CSV.read("icon_font_ignore_list.csv").map(&:first)
  icon_font_candidates.each do |iconName|
    # 忽略 IgnoreList 名单里的 Icon
    if ignore_list.include?(iconName)
      puts "  - ignore #{iconName} for ignore list."
      next
    end
    # 忽略特殊尺寸的 Icon
    covertName = convert_to_lower_camel_style(iconName)
    if iconSizeMap.keys.include?(covertName)
      puts "  - ignore #{iconName} for special size."
      next
    end
    # 将需要转换 iconFont 的图标文件移动到目标文件夹
    # `mv ./package/icons/#{iconName} ./temp/iconfont_icons/#{iconName}`

    # 将需要转换 iconFont 的图标文件复制到目标文件夹【这样可以既保留 font 信息，又保留图片信息，测试用】
    `cp ./package/icons/#{iconName} ./temp/iconfont_icons/#{iconName}`
  end
  # 生成新的 IconFont 字体文件
  `mkdir ../iconfont_output`
  `icon-font-generator ./temp/iconfont_icons/*.svg -n UniverseDesignIconFont --height=1000 -p anticon -o ../iconfont_output --center`
  # 将生成的 IconFont 字体文件拷贝到资源文件夹中
  `cp ../iconfont_output/UniverseDesignIconFont.ttf ../resources/UniverseDesignIconFont.ttf`
end

def generate_image_assets(enable_pdf)
  puts "\n📋 Generating Image Assets..."
  `mkdir -p ./temp/imageset_icons`
  `mv ./package/icons/* ./temp/imageset_icons`

  # icon 名称到资源名称的映射
  resourceNameMap = Hash.new
  iconTypeToFigmaNameMap = Hash.new

  # 部分 icon 需要更大的尺寸
  # 数据源：https://bytedance.feishu.cn/base/bascnolpzNCSGZzqbD3YhGbRrmg?table=tblv5khRvyAeByeb&view=vewzgWjcjg
  iconSizeMap = Hash.new
  iconSizeMap.default = 32
  CSV.foreach("icon_special_sizes.csv", :col_sep => "\t") do |row|
    iconSizeMap[row[0]] = row[1].to_i
  end
  # 部分 icon 使用 cariosvg 转换会有问题，改用 inkscape
  escapeSet = Set.new
  CSV.foreach("icon_use_inkscape.csv") do |row|
    escapeSet.add(row[0])
  end

  mutex = Mutex.new
  threads = []

  Pathname.new("./temp/imageset_icons").children.each do |path|
    threads << Thread.new do
      fileName = File.basename(path.basename, File.extname(path.basename))
      if fileName == ".DS_Store"
        next
      end
      # 跳过 DM 资源，合并入 LM 的 asset 中
      if fileName.end_with?("-dm")
        next
      end
      name = convert_to_lower_camel_style(fileName)
      # 创建资源文件
      if enable_pdf && fileName.downcase.include?("colorful") && iconSizeMap[name] > 32
        create_pdf_image_asset(fileName, fileName, iconSizeMap[name])
        # 创建 assets 会有小概率失败，这里暂时暴力地重试一次以解决问题
        create_pdf_image_asset(fileName, fileName, iconSizeMap[name])
      else
        create_png_image_asset(fileName, fileName, iconSizeMap[name], escapeSet.include?(name))
        # 创建 assets 会有小概率失败，这里暂时暴力地重试一次以解决问题
        create_png_image_asset(fileName, fileName, iconSizeMap[name], escapeSet.include?(name))
      end
      # resourceNameMap[name] = "icon_" + name
      mutex.synchronize do
        iconTypeToFigmaNameMap[name] = fileName
        resourceNameMap[name] = '.assetFile("' + fileName + '")'
      end
    end
  end

  # 等待所有线程完成
  threads.each(&:join)

  json = File.read("../iconfont_output/UniverseDesignIconFont.json")
  iconfontHash = JSON.parse(json)
  iconfontHash.keys.each do |iconName|
    camelIconName = convert_to_lower_camel_style(iconName)
    iconRawName = resourceNameMap[camelIconName]
    iconHashName = '\u{' + iconfontHash[iconName].gsub!('\\', "") + "}"
    resourceNameMap[camelIconName] = 'UDIcon.iconFontEnable ? .iconFont("' + iconHashName + '") : ' + iconRawName
  end

  File.open("./temp/iconNameMap.json", "w") do |f|
    # write the hash as JSON
    f.write(JSON.pretty_generate(resourceNameMap))
  end
  
  File.open("./temp/iconTypeToFigmaNameMap.json", "w") do |f|
    # write the hash as JSON
    f.write(JSON.pretty_generate(iconTypeToFigmaNameMap))
  end

  # 压缩 PNG 图片
  puts "\n🧽 Compressing Images..."
  compress_png_folder()
  # 编译 Assets
  `sh ./build_image_assets.sh`
end

def compress_png_folder()
  # Define the command to run the Python script
  command = "python3 ./compress_png_new.py --proj_dir ../resources"
  # Open a pipe to capture the output of the Python script
  stdout, stderr, status = Open3.capture3(command)
  # Print the output of the Python script
  puts stdout
end

def check_resource_integrity()
  puts "\n🔍 Checking resource integrity..."
  file = File.read("./package/replacement.json")
  icons = JSON.parse(file)
  missing_count = 0
  icons.each do |key, value|
    if !File.exist?("./package/icons/#{value["newIcon"]}.svg")
      puts "  - #{value["newIcon"]} is missing."
      missing_count += 1
    end
  end
  if missing_count == 0
    puts "  - ✅ All replacement icons exist."
  else
    puts "  - ❌ #{missing_count} replacement icons are missing."
  end
end

def check_resource_validity()
  puts "\n🔍 Checking resource validity..."
  # Set the path to the folder containing the SVG files
  folder_path = "./package/icons"
  invalid_count = 0
  # Traverse all files in the folder
  Dir.foreach(folder_path) do |filename|
    # Check if the file is an SVG file
    if filename.end_with?(".svg")
      # Load the SVG file
      file_path = File.join(folder_path, filename)
      File.open(file_path, "r") do |f|
        svg_contents = f.read()
        if svg_contents.include?("clipPath")
          invalid_count += 1
          puts "  - #{filename} contains <clipPath>."
        end
      end
    end
  end
  if invalid_count == 0
    puts "  - ✅ All icons files is valid."
  else
    puts "  - ❌ #{invalid_count} icons are invalid."
  end
end

def check_icon_font_generator_installation()
  puts "\n🔍 Checking icon font tools..."
  if `which icon-font-generator`.empty?
    puts "  - Install icon-font-generator..."
    # Do whatever is needed to install icon-font-generator
  else
    puts "  - icon-font-generator found in PATH"
  end
end

# 解析参数
options = {}
OptionParser.new do |opts|
  opts.on("--enable-pdf", "使用矢量图格式") do |p|
    options[:enable_pdf] = p
  end
end.parse!

# 检查必要工具
check_icon_font_generator_installation()
check_cairo_svg_installation()
# 清除资源文件夹
clean_previous_version_resources()
# 下载资源包
download_and_process_icon_resources(ARGV[0])
# 生成图片资源
generate_icon_resources(ARGV[0], options[:enable_pdf])
# 生成 Swift 文件
generate_swift_files(ARGV[0])
# 清理中间产物
clean_temporary_files()
