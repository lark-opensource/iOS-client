require 'json'
require 'psych'
require "base64"
require 'openssl'

# 通过podfile去获取组件信息
VersionReg_podfile = /(?<=')\d+(\.[a-zA-Z0-9\-]+)*(?=')/
NameReg_podfile = /(?<=pod ').*?(?=')/

# 通过podfile.lock去获取组件信息
VersionReg_podLock = /\((.+)\)/ #获取 - 和 ( 之间的组件名
NameReg_podLock = /(.+)\(/ #获取括号中的内容（版本号）

# 路径path
# TemplatePath = '${PODS_TARGET_SRCROOT}/script/podInfoDatasourceTem.erb'

PodfilePath = ENV['PODS_ROOT'] + '../Podfile'
PodfileLockPath = ENV['PODS_ROOT'] + '/Manifest.lock'

JsonTargetDir = ENV['PODS_CONFIGURATION_BUILD_DIR'] + '/EEPodInfoDebugger/EEPodInfoDebugger.bundle'
JsonTargetPath = JsonTargetDir + '/temp.data'

EnryptKey = 'thisIsPodInfoFromLarkkkkkkkkkkkk'
EnryptIv = 'thisIsIvForPodIn'

# ${PODS_CONFIGURATION_BUILD_DIR}/EEPodInfoDebugger/EEPodInfoDebugger.bundle

SwiftTargetPath = '../src/DebugPodInfosDataSource.swift'

# 保存pod里的组件信息
class PodInfoItem
  def initialize(name, version)
    @name = name
    @version = version
  end
  def name
    return @name
  end
  def version
    return @version
  end
end

# 给ERb使用的data
class PodInfoData
  def initialize(n)
    @infos = n
  end
  def get_binding
    binding
  end
end

class PodInfoGenerator
  # 工具方法用于获取path
  def getPath(path)
    fullPath = File.expand_path(path, File.dirname(__FILE__))
    fullPath
  end

  def getAbsolute(path)
    return path
  end

  def generatePodInfoData
    template = ERB.new(File.new(getAbsolute(TemplatePath)).read, nil, '-')
    contents = template.result(@infoData.get_binding)
    File.new(getPath(SwiftTargetPath), 'w').write(contents)
  end

  def getDependencyMapperFromLock
    lockPath = getAbsolute(PodfileLockPath)
    puts PodfileLockPath
    @lockMapper = Psych.load_file(lockPath)
    dataArray = Array.new
    for temp in Array["OPTIONAL DEPENDENCIES", "DEPENDENCIES"]
      @lockMapper[temp] ||= %w{}
      dependencies = @lockMapper[temp]
      dependencies.each{|line|
        name = "#{line.match(NameReg_podLock)}"
        version = "#{line.match(VersionReg_podLock)}"
        begin
          if version && !version.include?("from")
            warn "name: #{name}, version: #{version}"
            version = version.gsub! '(= ', ''
            version = version.gsub! ')', ''
            name = name.gsub! ' (', ''
            item = {"name" => name, "version" => version}
            dataArray.push(item)
          end
        rescue
          warn("#{line}: #{$!}")
        end
      }
    end
    @dataArray = dataArray
  end

  def generateJsonFileFromDataArray
    jsonTemp = {"data" => @dataArray}
    json = JSON.pretty_generate(jsonTemp)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.encrypt
    cipher.key = EnryptKey
    cipher.iv  = EnryptIv
    encrypted = cipher.update(json) + cipher.final
    encryJson = encrypted
    File.new(getPath(JsonTargetPath), 'w').write(encryJson)
  end
end

# 直接生成json资源文件去读取
def generate_pod_infos_json
  generator = PodInfoGenerator.new
  generator.getDependencyMapperFromLock
  generator.generateJsonFileFromDataArray
end

generate_pod_infos_json()

