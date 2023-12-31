# frozen_string_literal: true

# @!domain [Rake::DSL]

require 'yaml'

task :pull do
  system('git stash; git pull --rebase; git stash pop')
  system('bundle install')
  system('scripts/pod-rp')
  system('bundle exec pod install')
  system('open Lark.xcworkspace')
end

task :setup do
  system('command -v bundler > /dev/null || gem install bundler')
  system('bundle install')
end

# 输出 Lark 依赖 pod
task :allPods do
  # 解析 podlock 文件
  def parsePodfileLock(path)
    podfileLock = YAML.load_file(path)
    pods = {}

    podfileLock['PODS'].each do |item|
      if item.instance_of?(Hash)
        pod, version = parsePodAndVersion(item.keys[0])
      else
        pod, version = parsePodAndVersion(item)
      end
      pods[pod] = version
    end
    return pods
  end

  # 解析 pod name 和 version
  def parsePodAndVersion(message)
    items = message.split(' ')
    return items[0].split('/')[0], items[1]
  end

  larkPods = parsePodfileLock('./Podfile.lock')
  larkPods.each do |key, value|
    puts "#{key}, #{value}"
  end
end

# 对比 iOS-client的podfile.lock与指定podfile.lock文件的区别 （后者为基线）
task :compare, [:podfile] do |_task, args|
  # 解析 podlock 文件
  def parsePodfileLock(path)
    podfileLock = YAML.load_file(path)

    pods = podfileLock['SPEC CHECKSUMS'].keys

    return pods
  end

  comparedPods = parsePodfileLock('./Podfile.lock')
  basePods = parsePodfileLock(args[:podfile])

  increased = comparedPods - basePods
  deleted = basePods - comparedPods
  puts "increased: #{increased.length}\n"
  increased.each do |item|
    puts "\033[32m#{item}\033[0m"
  end
  puts "deleted: #{deleted.length}\n"
  deleted.each do |item|
    puts "\e[31m#{item}\e[0m"
  end
end

# xcode 适配日志
task :xcode do
  message = <<-MESSAGE

  2020年5月13
  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  自2020年5月13日起，ios-client 的主分支已经支持使用Xcode11.4或以上版本编译，但是仍不建议升级；因为Release/3.24
  及之前的版本仍需维护一段时间，或者你可以选在安装两个版本。
  具体原因请参考：https://bytedance.feishu.cn/wiki/wikcnCNTP9VU7FWS7d77GjdgnSh
  Xcode11.3.1 下载链接：https://developer.apple.com/download/more/

  Since May 13, 2020, the master branch of ios-client has been able to compile using Xcode11.4 or higher,
  but it is not recommended to upgrade as Release/3.24 and previous releases will still need to be maintained
  for some time. Or you can choose to install both versions.
  Reasons：https://bytedance.feishu.cn/wiki/wikcnCNTP9VU7FWS7d77GjdgnSh
  Xcode11.3.1 download link：https://developer.apple.com/download/more/


  2020年8月18
  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  2020年8月18起，可以尝试开始使用最新的Xcode(11.6)开发项目，但是，为了保证稳定性，Jenkins仍默认使用 Xcode11.3.1。

  Starting from August 18, 2020, you can try to start using the latest Xcode(11.6) development project,
  but to ensure stability, Jenkins still use Xcode11.3.1 by default.


  2020年9月22
  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  2020年9月22起，可以尝试开始使用最新的 Xcode12 开发项目，但是，为了保证稳定性，Jenkins仍默认使用 Xcode11.3.1。
  注意：Xcode12 构建非常慢，大概要花xcode11双倍的时间。

  Starting from September 22, 2020, you can try to start using the latest Xcode12 development project,
  but to ensure stability, Jenkins still use Xcode11.3.1 by default.
  Note: Xcode12 build is very slow, taking about twice as long as XCode11.


  2020年10月15
  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  自2020年10月16日（Lark-Version: 3.36.0-alpha）起，打包任务将切换为使用Xcode12(Swift5.3)构建。
  Starting October 16, 2020 (Lark-Version: 3.36.0-alpha), the packaging task will switch to build with Xcode12(Swift5.3).

  Xcode 适配记录

  MESSAGE
  puts "\033[36m #{message}\033[0m\n"
end

# require cocoapods and load plugin. so later can use podfile and install without acctually invoke a command
task :prepare_cocoapods do
  require 'bundler/setup' # ensure use same bundle environment
  require 'cocoapods'
  %w[claide cocoapods].each do |plugin_prefix|
    CLAide::Command::PluginManager.load_plugins(plugin_prefix)
  end
end

# fetch odr resources and change xcodeproj odr settings
task :fetch_odr_resources do
  require 'xcodeproj'
  require_relative 'fastlane/lib'  
  require 'lark/project/environment'

  git_root_path = `git rev-parse --show-toplevel`.strip
  odr_dir_name = "odr_resources" 
  odr_dir = git_root_path + "/#{odr_dir_name}"      

  # clean up & set up 
  `rm -rf #{git_root_path}/../ODR` if File.exists? "#{git_root_path}/../ODR"  
  `rm -rf #{odr_dir}` if File.exists? odr_dir  
  `mkdir #{odr_dir}`
    
  # fetch open_platform odr resources
  plist = Apple::ApplePlist.load(git_root_path + "/Lark/Info.plist")  
  version = plist["CFBundleShortVersionString"]
  raise "Get version error" if (version || "").length == 0
  $lark_env = Lark::Project::Environment.instance
  channel = plist["KA_CHANNEL"] || ($lark_env.is_oversea ? "Lark" : "Feishu")  

  cmd = "python3 bin/dispose_odr.py --channel #{channel} --version #{version} --output_path #{odr_dir}"
  puts "Fetching open platform odr resources with cmd: #{cmd}"
  puts `#{cmd}`  
  
  raise "Fetching ODR resource error, please contact: supeng.charlie" if Dir.glob("#{odr_dir}/*.zip").length == 0

  if Dir.glob("#{odr_dir}/*.json").length > 0
    if !File::exist?("Modules/OpenPlatform/TTMicroApp/Timor/Resources/BuildinResources.bundle")
      cmd = "`mkdir Modules/OpenPlatform/TTMicroApp/Timor/Resources/BuildinResources.bundle`"
      puts cmd
      puts `#{cmd}`.strip
    end
    Dir.glob("#{odr_dir}/*.json").each do |json_file|
      cmd = "`cp #{json_file} Modules/OpenPlatform/TTMicroApp/Timor/Resources/BuildinResources.bundle/`"
      puts cmd
      puts `#{cmd}`.strip
    end
  end

  # get all existing odr resources
  project = Xcodeproj::Project.open("#{git_root_path}/Lark.xcodeproj")      
  target = project.targets.find { |target| target.name == "Lark" }      
  all_existing_odr_resource = {}
  for file in target.resources_build_phase.files        
    if file.settings != nil and file.settings["ASSET_TAGS"] != nil 
      all_existing_odr_resource[file] = file.settings["ASSET_TAGS"]
      puts "Finding existed odr resource: #{file.file_ref.name}"
    end
  end 
  
  # # remove all existing odr resources
  # all_existing_odr_resource.keys.each do |file|
  #   tags = all_existing_odr_resource[file]
  #   tags.each do |tag|                   
  #     ref = file.file_ref
  #     target.remove_on_demand_resources({ tag => [ref] })
  #     puts "Removing tag: #{tag} and ref: #{ref.name}"
  #   end        
  # end
  # project.root_object.attributes["KnownAssetTags"] = []

  # add all odr resources based on fetch results
  Dir.chdir(git_root_path) do
    files = Dir.glob("#{odr_dir_name}/*.zip")    
    files.each do |file|
      file_ref = project.main_group.new_file(file)
      file_tag = file
      file_tag = file.split("/")[-1] if file.include? "/"
      file_tag = file_tag.split(".")[0...-1].join(".") if file_tag.include? "."
      target.add_on_demand_resources({ file_tag => [file_ref]})
      puts "Adding odr resource: #{file}"
    end
  end
        
  project.save() if project.dirty?
end

task :check_if_pod do
  require 'cocoapods'
  require 'lark/project/if_pod_helper'
  require 'lark/project/podfile_mixin'
  require_relative 'if_pod.rb'
  require 'yaml'

  podfile = Pod::Podfile.new
  if_pod_cache = podfile.lark_main_target_if_pods

  def generate_subspec_hash(dir)
    pod_lock = YAML.load_file("#{dir}/Podfile.lock")
    pods_with_subspec_hash = {}
    raw_value = []
    pod_lock['PODS'].each do |v|
      if v.is_a? String
        raw_value << v
      elsif v.is_a? Hash
        v.each_key { |temp| raw_value << temp }
        v.values.flatten.each { |temp| raw_value << temp }
      end
    end

    raw_value.each do |v|
      pods_with_subspec = v.split(' (').first
      if pods_with_subspec.include? '/'
        pod_name = pods_with_subspec.split('/').first
        subspec = pods_with_subspec.split('/')[1...].join('/')
        pods_with_subspec_hash[pod_name] ||= Set.new
        pods_with_subspec_hash[pod_name] << subspec
      else
        pods_with_subspec_hash[pods_with_subspec] ||= Set.new
      end
    end
    pods_with_subspec_hash
  end
  def generate_version_hash(dir)
    pod_strict_lock = YAML.load_file("#{dir}/Podfile.strict.lock")
    pods_with_version_hash = {}
    pod_strict_lock.each do |v|
      pod_name = v.split(' (').first
      pod_source_and_version = v.split(' (').last
      if pod_source_and_version.include? ', from'
        version = pod_source_and_version.split(', from').first
        pods_with_version_hash[pod_name] = version
      end
    end
    pods_with_version_hash
  end
  def generate_non_local_pods(dir)
    non_local_pods = Set.new
    pod_lock = YAML.load_file("#{dir}/Podfile.lock")
    pod_lock['SPEC CHECKSUMS'].keys.each do |pod|
      non_local_pods << pod unless pod_lock['EXTERNAL SOURCES'].keys.include? pod
    end
    non_local_pods
  end

  ios_client_subspec_hash = generate_subspec_hash Dir.pwd
  ios_client_version_hash = generate_version_hash Dir.pwd
  ios_client_non_local_pod = generate_non_local_pods Dir.pwd

  if_pod_cache_set = Hash.new
  if_pod_cache.each do |cache|
    cache_version = cache[2] if cache[2].is_a? String
    cache_subspecs = cache.last[:subspecs] if cache.last.is_a? Hash
    if_pod_cache_set[cache[1]] = [cache_version || "", (cache_subspecs || Array.new).to_set]
  end
  
  should_add_if_pods = []
  ios_client_non_local_pod.each do |non_local_pod|
    pod_lock_version = ios_client_version_hash[non_local_pod]
    pod_lock_specs = ios_client_subspec_hash[non_local_pod]
    if if_pod_cache_set[non_local_pod].nil?
      if pod_lock_specs.length == 0
        should_add_if_pods << "if_pod '#{non_local_pod}', '#{pod_lock_version}'"
      else
        should_add_if_pods << "if_pod '#{non_local_pod}', '#{pod_lock_version}', subspecs: %w[#{pod_lock_specs.join " "}]"
      end
    end
  end
  if should_add_if_pods.length > 0    
    raise "#{should_add_if_pods.join "\n"} \n are not register in if_pod.rb, please add them to if_pod.rb. Contact supeng.charlie for more information"    
  end
end
# see also rakelib/*.rake, which will be autoload
