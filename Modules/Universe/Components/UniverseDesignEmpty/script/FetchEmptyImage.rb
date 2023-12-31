require 'erb'
require 'pathname'
require 'csv'

require_relative './EmptyImageSetting'

# DownLoad illustration From https://bnpm.byted.org/@universe-design
def download(version)
  `rm -rf ../illustrations`
  `curl https://bnpm.byted.org/@universe-design/illustration/download/@universe-design/illustration-#{version}.tgz --output illustration.tgz`
  `tar xzf illustration.tgz`
  `rm -rf illustration.tgz`
  `mv ./package/illustrations ../illustrations`
  `rm -rf ./package`
  EmptyImageSet::IgnoreList.list.each do |fileName|
    puts fileName
    `rm -rf ../illustrations/#{fileName}.svg`
    name = convertToVeriableName(fileName)
    `rm -rf ../resources/Media.xcassets/#{name}.imageset`
  end
#  `rm -rf ../resources/Media.xcassets/*.imageset`
end

# 转换为代码中的变量名，移除 icon 前缀，转换为驼峰命名
def convertToVeriableName(fileName)
  name = fileName.dup
  name.slice! "illustration_"
  name.gsub!('-', '_')
  # 转换为驼峰命名
  name = name.split('_').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
  return name
end

# 文件名、代码中变量名、icon 尺寸 (单位 pt)
def buildImageSet(fileName, name, sizeInPoint)
  # 是否有对应的 DM 资源
  hasDM = File.exist?("../illustrations/#{ fileName }_dm.svg")
  size1X = sizeInPoint
  size2X = sizeInPoint * 2
  size3X = sizeInPoint * 3
  puts "Processing #{ fileName }, resources name: #{ name }, has DM: #{ hasDM }, size: #{ sizeInPoint }"
  %x{
    if [ -d ./#{ name }.imageset ]; then
      rm -rf ./#{ name }.imageset
    fi

    mkdir ./#{ name }.imageset
    cairosvg ../illustrations/#{ fileName }.svg --output-width #{ size2X } --output-height #{ size2X } -o ./#{ name }.imageset/#{ name }@2x.png
    cairosvg ../illustrations/#{ fileName }.svg --output-width #{ size3X } --output-height #{ size3X } -o ./#{ name }.imageset/#{ name }@3x.png
  }

  if hasDM
    %x{
      cairosvg ../illustrations/#{ fileName }_dm.svg --output-width #{ size2X } --output-height #{ size2X } -o ./#{ name }.imageset/#{ name }-dm@2x.png
      cairosvg ../illustrations/#{ fileName }_dm.svg --output-width #{ size3X } --output-height #{ size3X } -o ./#{ name }.imageset/#{ name }-dm@3x.png
    }
  end

  if hasDM
    jsonTemplate = File.read('Contents.json.dm.erb')
  else
    jsonTemplate = File.read('Contents.json.erb')
  end

  b = binding
  b.local_variable_set(:filename, name)

  json = ERB.new(jsonTemplate, 0, "%<>")

  jsonFile = File.new("./#{ name }.imageset/Contents.json", "w")
  jsonFile.puts json.result(b)
  jsonFile.close

  %x{
    if [ -d ../resources/Media.xcassets/#{ name }.imageset ]; then
      rm -rf ../resources/Media.xcassets/#{ name }.imageset
    fi

    `mv -f ./#{ name }.imageset ../resources/Media.xcassets/`
  }
end

def writeFile()

  iconSizeMap = Hash.new
  iconSizeMap.default = 100
  CSV.foreach("SpecialSize.csv", :col_sep => "\t") do |row|
    iconSizeMap[row[0]]=row[1].to_i
  end

  # Set up template data.
  iconNames = Array.new

  Pathname.new('../illustrations').children.each do |path|
    fileName = File.basename(path.basename, File.extname(path.basename))
    if fileName == '.DS_Store'
      next
    end
    # 跳过 DM 资源，合并入 LM 的 asset 中
    if fileName.end_with?('_dm')
      next
    end
    # 非 empty 的资源跳过
    if fileName["empty"]
      name = convertToVeriableName(fileName)
      buildImageSet(fileName, name, iconSizeMap[name])
      iconNames.push(name)
    else
      puts "skip file: #{ fileName }, because it's not an empty resource"
    end
  end

  `python3 ./compress_png.py --proj_dir ../resources`

  iconNames.sort!

  b = binding
  b.local_variable_set(:iconNames, iconNames)

  `rm -rf ../illustrations`
  `rm -rf ./.compress_record.json`
  `rm -rf ./pngquant.zip`
  `rm -rf ./pngquant`
end

download(ARGV[0])
writeFile()
