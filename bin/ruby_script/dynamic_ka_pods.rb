require 'net/http'
require 'json'
require 'logger'
require 'pathname'
require 'yaml'
require 'fileutils'

#脚本绝对路径：/Users/bytedance/Documents/lark/iOS-client/bin/ruby_script/ka_dynamic_pods.rb
$logger = Logger.new(STDOUT)
$rb_script_path = File.dirname(__FILE__ )
$logger.info "rb_script_path: " + $rb_script_path
if %x(cd #{$rb_script_path};git rev-parse --is-inside-work-tree).strip != "true"
  puts '目录非git仓库，请检查目录后重试'
  exit -1
end
$iOS_client_path = %x(git rev-parse --show-toplevel).strip
$logger.info "iOS_Clinet Path:" + $iOS_client_path
$info_plist_path = File.expand_path("Lark/Info.plist", $iOS_client_path)
$config_yaml_path = File.expand_path("config/arch.yml", $iOS_client_path)
$logger.info "Config_yaml_path: " + $config_yaml_path
$native_component_name = ENV['native_component_name']
# 某些需要注册用户态的情况下，如果使用@_silgen_name进行注册，需要在export_symbol_file里面添加符号，为了不影响saas，在脚本里面添加
$Export_Symbol_Path = File.expand_path("bin/export_symbol_file.txt", $iOS_client_path)
$Export_Symbol_List = ['_Lark.OpenChat.Messenger.KAMessage', '_Lark.OpenChat.Messenger.KAMenu']
#读取info.plist中对应字段，获取用于请求TCC服务参数。
def read_info_plist(info_plist_path)
  begin
    info_plist = File.read(info_plist_path)
    $logger.info "Info.plist read success."
  rescue
    $logger.error "Info.plist read error."
    return
  end
  IO.popen('plutil -convert xml1 -r -o - -- -', 'r+') do |f|
    f.write(info_plist)
    f.close_write
    info_plist = f.read
    return info_plist
  end
end

#解压压缩的原生集成pod文件
def unzip(filename)
  command = "unzip -o #{filename} -d #{$iOS_client_path} > /dev/null"
  success = system(command)
  success && $?.exitstatus == 0
end

# 判断文件是否存在，存在则删除缓存
def file_exist_and_create(file_path)
  if !File.exist?(file_path)
    $logger.info "Set new #{file_path}."
    File.new(file_path, "w+")
  else
    $logger.info "#{file_path} has already exist!"
    File.delete(file_path)
    File.new(file_path, "w+")
  end
end

def get_config(info_plist)
  #release_channel字段
  channel = ENV["KA_TYPE"]
  $logger.info "Release Channel: #{channel}"
  #version_number字段
  version = info_plist.scan(/<key>CFBundleShortVersionString<\/key>\s+<string>(.+)<\/string>/).flatten.first
  $logger.info "App Version: #{version}"
  uri= URI("https://cloudapi.bytedance.net/faas/services/tttswszxlemb2szaz8/invoke/getKAClientBuildData")
  params = {:channel => channel, :version => version, :platform => "ios", :supportIntegrationTypeArray => [0x00000001,0x00001000,0x0002000,0x0003000]}
  uri.query = URI.encode_www_form( params )

  config = Net::HTTP.get(uri)
  res =  Net::HTTP.get_response(uri)

  if res.code == "200"
    $logger.info"TCC requset success."
  else
    $logger.error"TCC request error!"
    return
  end
  config = JSON.parse(config)
  return config
end

def change_export_symbol_file()
  f = File.open($Export_Symbol_Path, "a")
  $Export_Symbol_List.each do |symbol|
    f.puts(symbol)
  end
end

def is_alchemy(config)
  is_alchemy_client = false
  third_pods_dynamic = false
  if config["data"] && config["data"].has_key?("client_alchemy_dependency") && config["data"]["client_alchemy_dependency"].has_key?("integrationMode")
    is_alchemy_client = true
    $logger.info "触发原生集成在线or离线构建 #{is_alchemy_client}"
    if config["data"]["client_alchemy_dependency"]["integrationMode"] == 2
      third_pods_dynamic = true
      $logger.info "触发三方库静态转动态 #{third_pods_dynamic}"
    end
  else
    $logger.info "不需要原生集成构建"
  end
  return is_alchemy_client, third_pods_dynamic
end

# 判断是否需要原生集成，导入需要改为动态库的源码Pod和SDK
def alchemy_dynamic_library(third_pods_dynamic, source_temp_file, sdk_temp_file)
  if third_pods_dynamic
    config_yaml_data = YAML.load_file($config_yaml_path)
    source_dynamic_pods_list = config_yaml_data['KA']['layer=ka-alchemy, biz=component']
    sdk_dynamic_sdk_list = config_yaml_data['KA']['layer=ka-alchemy, biz=external']
    $logger.info "源码静态转为动态库列表为: #{source_dynamic_pods_list}"
    $logger.info "sdk类静态转动态库列表为：#{sdk_dynamic_sdk_list}"
    # 源码类处理
    source_dynamic_pods_list.each do | item |
      source_temp_file.puts(item)
    end
    # SDK类处理
    sdk_dynamic_sdk_list.each do | sdk_info |
      sdk_name = sdk_info.match(/(.*?)\((.*?)\)/)[1]
      version = sdk_info.match(/(.*?)\((.*?)\)/)[2]
      info = "pod '#{sdk_name}', '#{version}'"
      sdk_temp_file.puts(info)
    end
  else
    $logger.info "非原生集成在线离线构建, 不需要转换为动态库。"
  end
end

def rename_podspec(directory, pod_name)
  folder_name = File.basename(directory)
  podspec_name = folder_name.split("_")[-1]
  podspec_file = File.join(directory, "#{podspec_name}.podspec")
  # 检查 Podspec 文件是否存在
  if File.exist?(podspec_file)
    new_podspec_file = File.join(directory, "#{pod_name}.podspec")
    # 重命名 Podspec 文件
    FileUtils.mv(podspec_file, new_podspec_file)
    # 读取新的 Podspec 文件内容
    podspec_content = File.read(new_podspec_file)
    # 替换 s.name 字段为文件夹名称
    modified_content = podspec_content.gsub(/(s\.name|spec\.name)\s*=\s*['"].*['"]/, "\\1 = '#{pod_name}'")
    # 写入修改后的内容到新的 Podspec 文件
    File.write(new_podspec_file, modified_content)
    puts "成功修改 Podspec 文件：#{new_podspec_file}"
  else
    puts "Podspec 文件不存在：#{podspec_file}"
  end
end

def download_additionals(path, name, source)
  additional_file = path + "/#{name}.zip"
  system("mkdir #{path}")
  $logger.info "appexFilePath: #{path}"
  File.write(additional_file, Net::HTTP.get(URI.parse(source)))
  if File.exist?(additional_file)
    $logger.info "Additional: #{name} download success."
  end
  system("unzip -o #{additional_file} -d #{path}")
  File.delete(additional_file)
end

# 处理http类source地址的动态集成方式
def deal_http_source_pod(integration_type, pod_name, pod_source)
  ka_plugIns_path = $iOS_client_path + "/KAPlugIns"
  ka_bundles_path = $iOS_client_path + "/KABundles"
  ka_extension_path = $iOS_client_path + "/KAExtensions"
  if integration_type == 1 or integration_type == 256
    temp_podname = pod_name.split("_")[-1]
    pod_zipfile=$iOS_client_path+"/#{temp_podname}.zip"
    $logger.info "podZipfile: #{pod_zipfile}"
    File.write(pod_zipfile, Net::HTTP.get(URI.parse(pod_source)))
    if File.exist?(pod_zipfile)
      $logger.info "Pod: #{temp_podname} download success."
    end
    unzip(pod_zipfile)
    temp_pod_path = $iOS_client_path + "/#{temp_podname}"
    pod_path = $iOS_client_path+"/#{temp_podname}"
    list = "pod '#{temp_podname}', :path => '#{pod_path}'"
    File.delete(pod_zipfile)
    # 这里处理下podspec里面的逻辑，由于目前上线会影响其他KA分支，暂时屏蔽
#    File.rename(temp_pod_path, pod_path)
#    rename_podspec(pod_path, pod_name)
    return list
  elsif integration_type == 4096
    download_additionals(ka_plugIns_path, pod_name, pod_source)
    return
  elsif integration_type == 8192
    download_additionals(ka_bundles_path, pod_name, pod_source)
    return
  elsif integration_type == 12288
    download_additionals(ka_extension_path, pod_name, pod_source)
    return
  end
end

# ka alchemy对外暴露组件动态库
def ka_public_pods_dynamic(is_alchemy_client, file)
  if is_alchemy_client == true
    $logger.info "开始构建列表数据"
    alchemy_pods = [
      'LarkKAEMM',
      'LKAppLinkExternalAssembly',
      'LKNativeAppExtensionAbility',
      'LKLifecycleExternalAssembly',
      'LKKeyValueExternalAssembly',
      'LKQRCodeExternal',
      'LKKeyValueExternal',
      'LKNativeAppExtension',
      'LKKACore',
      'LKAppLinkExternal',
      'LKQRCodeExternalAssembly',
      'LKNativeAppContainer',
      'LKStatisticsExternal',
      'LKStatisticsExternalAssembly',
      'LKPassportExternal',
      'LKPassportExternalAssembly',
      'LKWebContainerExternal',
      'WebBrowser/KA',
      'LKKAContainer',
      'LarkKASDKAssemble/KA',
      'LKTabExternal',
      'LKLoggerExternal',
      'LKLoggerExternalAssembly',
      'LKJsApiExternal',
      'KAEMMService',
      'LKMessageExternalAssembly',
      'LKMenusExternalAssembly',
      'LKMessageExternal',
      'LKMenusExternal'
    ]

    alchemy_pods.each { |item|
      file.puts("pod '#{item}'")
    }
  end
end

#temp文件生成方法
def temp_file_inject(config)
  is_alchemy_client, third_pods_dynamic = is_alchemy(config)
  tempPath = File.join($iOS_client_path, "ka_dynamic_pods")
  ka_dynamic_pods_list = File.join($iOS_client_path, "bin/ka_resource_replace/ka_dynamic_pods_list")

  #判断两个缓存文件是否存在，存在则删除缓存新建
  file_exist_and_create(tempPath)
  file_exist_and_create(ka_dynamic_pods_list)

  f = File.open(tempPath, "w")
  dynamic_pods_list_file = File.open(ka_dynamic_pods_list, "w")

  if config["errorCode"] == 0
    # 对外暴露的alchemy组件动态化
    ka_public_pods_dynamic(is_alchemy_client, f)
    #判断哪些pod需要改为动态库
    alchemy_dynamic_library(third_pods_dynamic, dynamic_pods_list_file, f)
    #加一层防护逻辑
    if config["data"]["client_component_dependency"].nil?
      $logger.info "client_component_dependency is empty!"
      return
    end
    config["data"]["client_component_dependency"].each { |item|
      #集成组件名称
      pod_name = item["component"]
      #集成组件版本
      pod_version = item["component_version"].strip!
      #集成组件仓库地址
      pod_source = item["component_source"]
      #集成组件类型
      integration_type = item["integrationType"]
      #如果tcc上Source地址为http开头，需要从远端拉zip文件然后解压到本地走pod本地依赖，资源和插件类仅缓存到ios-Client文件夹中
      if pod_source.start_with?("http") && !pod_source.end_with?("git")
        list = deal_http_source_pod(integration_type, pod_name, pod_source)
      else
        if !pod_version.nil?
          list = "pod '#{pod_name}', '#{pod_version}'"
        else
          list = "pod '#{pod_name}'"
        end
      end
      if pod_name != $native_component_name && !list.nil?
        $logger.info "list write into tempfile: #{list}"
        f.puts(list)
        $logger.info "#{pod_name}未与重名的检测pod冲突，正常动态集成"
      end
    }
  else
    $logger.error "Error code from TCC is not 0."
    return
  end
end

def update_info_plist_if_needed(config, info_plist)
  $logger.info "config: #{config}"
  value = config.fetch('data', nil).fetch('client_alchemy_dependency', nil).fetch('alchemy_version_code', nil)
  if value
    $logger.info "修改 alchemy version: #{value}"
    info_plist.gsub!('{alchemy_version_code}', value.to_s)
    File.write($info_plist_path, info_plist)
  else
    $logger.info "不修改 alchemy version"
  end
end

info_plist = read_info_plist($info_plist_path)
config = get_config(info_plist)

update_info_plist_if_needed(config, info_plist)
temp_file_inject(config)
change_export_symbol_file

