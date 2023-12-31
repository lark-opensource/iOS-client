require 'json'
require 'erb'

# const config
ConfigJSONPath = './apmevent_config.json'
SwiftTemplatePath = './apmevent_template.erb'
DistDirPath = './dist'
APMConstSwiftPath = '../MailSDK/Mail/Services/MailAPMMonitor/MailAPMConstant.swift'

CONFIG_KEY_EVENTS = "Events"
CONFIG_KEY_KEY = "Key"
CONFIG_KEY_SCENE = "Scene"
CONFIG_KEY_PAGE = "Page"
CONFIG_KEY_LATENCY = "LatencyDetails"
CONFIG_KEY_METRICS = "Metrics"
CONFIG_KEY_CATEGORY = "Category"

REGAPMKEY_START = '*** APMSCRIPT EVENTKEY ***'
REGAPMEKY_END = ' *** APMSCRIPT EVENTKEY_END ***'
REGAPM_REG_KEY = /\=.+\"/ #获取“= ” “"” 的内容

REGAPMKEY_PAGE_START = '*** APMSCRIPT PAGE ***'
REGAPMEKY_PAGE_END = ' *** APMSCRIPT PAGE_END ***'
REGAPM_REG_PAGE = /case(.*)/ #case之后的内容

# helper
def colorize(text, color_code)
  colorText = "\e[#{color_code}m#{text}\e[0m"
  puts colorText
end
def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end

def getPath(path)
  fullPath = File.expand_path(path, File.dirname(__FILE__))
  fullPath
end

# Class Define
class EventParam
  @key = ""
  @type = ""
  @const_value = []

  def initialize(key)
    @key = key
    @const_value = []
  end

  def key
    @key
  end

  def type=(type)
    @type = type
  end

  def const_value=(value)
    @const_value = value
  end

  def hasAssociateValue
    flag = false
    if @const_value.empty? # 采用关联值形式
      flag = true
    end
    flag
  end

  def swiftEnumConst # 返回的是数组
    array = []
    for value in @const_value
      array.push("#{@key}_#{value}")
    end
    array
  end

  def swiftEnumKey(needValue)
    res = ".#{@key}(_)"
    if needValue
      res = ".#{@key}(let value)"
    end
    res
  end

  def swiftEnumAssociated
    value = @key + "(#{@type})"
    value
  end

  def defaultCase
    res = ""
    if @type == "String"
      res = "#{key}(\"\")"
    elsif @type == "Int"
      res = "#{key}(0)"
    end
    res
  end

  # 主要用来获取枚举的key
  def defaultEnumValue
    if hasAssociateValue
      defaultCase
    else
      swiftEnumConst.first
    end
  end
end

class Event
    @key_name = ""
    @scene = ""
    @page = ""
    @lantencyDetails = [] # EventParam
    @metrics = [] #EventParam
    @category = [] #EventParam

    def initialize(key_name, scene, page, lantencyDetails, metrics, category)
      @key_name = key_name
      @scene = scene
      @page = page
      @lantencyDetails = lantencyDetails
      @metrics = metrics
      @category = category
    end

    def key_name
      @key_name
    end

    def page
      @page
    end

    def lantencyDetails
      @lantencyDetails
    end

    def metrics
      @metrics
    end

    # 类名，去掉下划线改驼峰
    def swiftEventClass
      name = @key_name.delete_prefix("mail_")
      name = name.split('_').collect(&:capitalize).join
      name
    end

    def swiftScene
      value = "." + @scene
      value
    end

    def swiftPage
      value = "." + @page
      value
    end

    def paramAll
      value = @category + @lantencyDetails + @metrics
      value
    end
end


# helper 工具方法
def getParamFromJsonObject(map)
  params = []
  map.each { |key, value|
    param = EventParam.new(key)
    if value.class == String
      param.type = value
    elsif value.class == Array # 里面是常量值，目前仅支持String
      param.type = "String"
      param.const_value = value
    end
    params.push(param)
  }
  params
end


# 主要流程代码会放到这里
class Creator
  @configEventList = []
  @existKeyList = []
  @existPageList = []

  # 从MAILAPMConst内获取现有的eventKey，为了避免重复
  def loadExistKeyConfig
    filepath = getPath(APMConstSwiftPath)
    started = false # 是否进入key区域
    list = []
    File.open(filepath,"r+"){|f|
      f.each_line{|line|
        if line.include? REGAPMKEY_START
          started = true
        elsif line.include? REGAPMEKY_END
          started = false
        else
          if started
            if line.include? "case"
              keyString = "#{line.match(REGAPM_REG_KEY)}"
              keyString = keyString.gsub! '= ', ''
              keyString = keyString.gsub! '"', ''
              list.push(keyString)
            end
          end
        end
      }
    }
    @existkeyList = list
    yellow("目前已定义的Key: #{list}")
  end

  # 从MAILAPMConst内获取现有的Page，为了避免重复
  def loadExistPageConfig
    filepath = getPath(APMConstSwiftPath)
    started = false # 是否进入key区域
    list = []
    File.open(filepath,"r+"){|f|
      f.each_line{|line|
        if line.include? REGAPMKEY_PAGE_START
          started = true
        elsif line.include? REGAPMEKY_PAGE_END
          started = false
        else
          if started
            if line.include? "case"
              keyString = "#{line.match(REGAPM_REG_PAGE)}"
              keyString = keyString.gsub! 'case ', ''
              list.push(keyString)
            end
          end
        end
      }
    }
    @existPageList = list
    yellow("目前已定义的Page: #{@existPageList}")
  end

  # 增加EventKey & Page 如果有必要的话
  def addKeyAndPageIfNeeded
    newKey = []
    newPage = []
    for config in @configEventList
      newKey.push(config.key_name)
      newPage.push(config.page)
    end
    content = ''
    lastLine = ''
    filepath = getPath(APMConstSwiftPath)
    keyPart = false # 是否进入key区域
    pagePart = false # 是否进入page区域
    File.open(filepath,"r+"){|f|
      f.each_line{|line|
        lastLine = line
        if line.include? REGAPMKEY_PAGE_START
          content = content + line
          pagePart = true
        elsif line.include? REGAPMEKY_PAGE_END
          # 插入page逻辑最后再加上end这行
          for page in newPage
            if not @existPageList.include?(page)
              content = content + "        case #{page}\n"
            end
          end
          content = content + line
          pagePart = false
        elsif line.include? REGAPMKEY_START
          content = content + line
          keyPart = true
        elsif line.include? REGAPMEKY_END
          # 插入page逻辑最后再加上end这行
          for key in newKey
            if not @existkeyList.include?(key)
              enum = key.split('_').collect(&:capitalize).join
              first = enum.chr
              enum = enum.delete_prefix(first)
              enum = first.downcase + enum
              content = content + "        case #{enum} = \"#{key}\"\n"
            end
          end
          content = content + line
          keyPart = false
        else
          content = content + line
        end
      }
    }
    File.open(filepath, 'w') do |f|
      f.write(content)
    end
  end


  # 从config配置中加载信息
  def loadConfig
    json = File.read(getPath(ConfigJSONPath))
    obj = JSON.parse(json)
    jsonEvents = obj[CONFIG_KEY_EVENTS]
    array = []
    for temp in jsonEvents
      lantencyDetails = getParamFromJsonObject(temp[CONFIG_KEY_LATENCY])
      metrics = getParamFromJsonObject(temp[CONFIG_KEY_METRICS])
      category = getParamFromJsonObject(temp[CONFIG_KEY_CATEGORY])
      event = Event.new(temp[CONFIG_KEY_KEY], temp[CONFIG_KEY_SCENE], temp[CONFIG_KEY_PAGE], lantencyDetails, metrics, category)
      array.push(event)
    end
    @configEventList = array
    yellow("
      配置文件中获取的Event为 👇🏻
      #{@configEventList}
      配置文件中获取的Event为 👆🏻")
  end

  # 检查
  def preCheck
    # TODO 做前置检查
  end

  # 输出swift event产物
  def outputEventSwift
    templateString = ""
    File.open(getPath(SwiftTemplatePath),"r").each_line do |line|
      templateString = templateString + line
    end
    # 模板执行
    template = ERB.new(templateString, nil, '-')
    res = template.result(binding)
    resultPath = getPath(DistDirPath + "/result.swift")
    File.open(resultPath, 'w') do |f|
      f.write(res)
    end
  end

  def create
    loadExistKeyConfig()
    loadExistPageConfig()
    loadConfig()
    preCheck()
    addKeyAndPageIfNeeded()
    outputEventSwift()
    green(
      "代码生成完成：请前往 Script/dist/result.swift 拷贝使用"
    )
  end
end


creator = Creator.new()
creator.create()
