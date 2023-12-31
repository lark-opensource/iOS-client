# rubocop:disable all

# @!domain [Pod::Podfile, Pod::Podfile::DSL::PodGroupDSL]

# @!parse
#  require 'cocoapods'

gem 'cocoapods', '1.13.0'

project 'Lark.xcodeproj'

require 'set'
require_relative './bin/ruby_script/podfile_tonic.rb'
# NOTE: 原来工程的各种方法扩展和通用配置，都移动到了下面这个脚本里，如果需要修改可以看对应的 bin/lib/lark-project/README.md
require 'lark/project/podfile_mixin'
# 工具链相关配置都移到下面的脚本
require 'lark/project/toolchain_manager'
require 'lark/project/remote_cache'
# NOTE: 需要和子仓同步的，限制版本和添加关联依赖，放在if_pod.rb文件里配置.
# if_pod相关功能介绍文档：https://bytedance.feishu.cn/wiki/wikcnshvOC5W18wpz5yxJGVL2Mf
require_relative './if_pod.rb'
# 子仓使用这个路径
# require 'lark/project/if_pod'
require_relative './remote_cache_enable_users.rb'
require 'lark/project/lark_assert.rb'
require 'lark/project/lark_setting.rb'
# 校验 Owner 配置
require_relative './bin/arch/owner/lib/validate'

`git config core.hooksPath hooks`
strict_lock_mode!
lark_patch_lldb!
local_use_module_nolto!

# 开启本地源码调试 rust-sdk，可自定义 rust-sdk 根目录 :path 与工程名 :proj_name
# 说明文档：https://bytedance.larkoffice.com/wiki/K2sywECpki2LC6kCFPrc03mSnXf
# rust_sdk_local_dev! :path => '../rust-sdk'

plugin 'cocoapods-monitor' # 覆盖率依赖其生成version.json

hummer_tags = {}
enable_remote_cache = false#暂时关闭, 感兴趣同学可以打开
if current_user_in_white_list
 enable_remote_cache = true
end

enable_remote_cache = try_to_enable_remote_cache(
    :remote_cache_enable => enable_remote_cache,
    :primary_branch => "develop",
    :final_target => "Lark",
    :hummer_tags => hummer_tags,
    :scheme_tag => 'lark.5'
)

hummer_tags["COCOAPODS_LINK_POD_CACHE"] = true if Lark::Misc.true? ENV['COCOAPODS_LINK_POD_CACHE']
hummer_tags["COCOAPODS_INTEGRATE_SPECIFIC_TARGETS"] = true if Lark::Misc.true? ENV['COCOAPODS_INTEGRATE_SPECIFIC_TARGETS']
hummer_tags["CODE_BYTED_ORG_PRIVATE_TOKEN"] = true if v = ENV['CODE_BYTED_ORG_PRIVATE_TOKEN'] and !v.empty?
hummer_tags["MAIN_BRANCH_STABILITY"] = true if v = ENV['LARK_HOURLY_BUILD'] and !v.empty?
hummer_tags["LARK_PACKAGE_BUILD"] = true if v = ENV['LARK_PACKAGE_BUILD'] and !v.empty?
hummer_tags["LARK_IOS_BUILD_VERIFY"] = true if v = ENV['LARK_IOS_BUILD_VERIFY'] and !v.empty? # pipeline中编译验证 xcodebuild会有这个tag
hummer_tags["XCODEBUILD_VERIFY"] = true if v = ENV['XCODEBUILD_VERIFY'] and !v.empty?  # pipeline中编译验证和打测试包 xcodebuild 会有这个tag
hummer_tags["LARK_BAZEL_TEST"] = true if v = ENV['LARK_BAZEL_TEST'] and !v.empty?  # 后置打包任务 中xcodebuild会有这个tag
hummer_tags["REMOTE_CACHE_PUBLISH"] = true if v = ENV['REMOTE_CACHE_PUBLISH'] and !v.empty?  # remote cache发布任务会有这个tag
hummer_tags["RUST_SDK_LOCAL_DEV"] = true if v = ENV['RUST_SDK_LOCAL_DEV'] and !v.empty?  # 开启本地源码调试 rust-sdk 时会有这个tag
hummer_tags["Lark_CD"] = true if (v = ENV['RUNTIME_TYPE'] || "") == "release"
lark_template_common_setup(hummer_tags: hummer_tags)

# See './bin/ruby_script/podfile_tonic.rb' for more detail.
clean_wrong_cache

disable_swiftlint! if respond_to?(:disable_swiftlint!)

# :all 全部的assert都会转为lldb断点, :none 全部的assert都会被忽略，转为控制台输出, "Modules/Biz" (or ["Moudles/Biz1", "Moudles/Biz2"]  )对单独或多个一个目录转lldb断点，其他目录忽略assert，转为控制台输出
# :disable 禁用改feature
# 你也可以在本地创建 Podfile.patch（请勿提交该文件！） 以固定配置某些库为源码或者二进制, 相关文档可见 https://bytedance.feishu.cn/wiki/wikcn5ZmvLm18TTTrwpIzNggwtf
assert_dir :all

# @param strategy:
#   :all 开启全部二进制
#   :pb 只有PB开启二进制
#   :other 手动开启二进制
# 你也可以在本地创建 Podfile.patch（请勿提交该文件！） 以固定配置某些库为源码或者二进制
# 修改后记得重新pod install
lark_use_common_binary_config(strategy: :all) do
  # NOTE: 这里面运行的代码，也可以放到`Podfile.patch`文件，会被自动加载运行。
  # `Podfile.patch`被ignore掉不会入库，这样可以按个人配置切换源码和二进制

  # 在 Ruby 中，`%w` 是一个字符串数组的快捷方式。
  # 它可以用来快速创建一个由空格分隔的字符串数组，其中每个字符串都不包含空格或其他特殊字符。
  # 具体来说，`%w` 会将字符串按照空格进行切割，并且返回一个字符串数组。
  #
  # 无须添加"逗号", "引号"，直接写模块名字，关于 %w 的介绍可以看上面。
  %w[
  ].each { |v| source v }

  #将Modules/#{dir}下所有pod切换成源码，参数为Modules下文件夹名字
  #e.g.: ByteView ByteWebImage Foundation Infra LarkLive LarkMedia LarkRVC LarkVoIP Mail Messenger Minutes Passport Security SpaceKit Todo
  # source_dir "SpaceKit"

  # additional patch config
  #覆盖率开启模块同时开始二进制
  if $lark_env.code_coverage_enable
    Lark::Project::ToolChainConfig.coverage_list.each { |v| source v }
  end
  #慢函数开启模块同时开启源码
  if $lark_env.evil_method_enable
    Lark::Project::ToolChainConfig.evil_method_list.each { |v| source v }
  end
  if $lark_env.hotpatch_enable
    Lark::Project::ToolChainConfig.hotpatch_list.each { |v| source v }
  end
  if $lark_env.frame_outlining_enable
    Lark::Project::ToolChainConfig.frame_outlining_list.each { |v| source v }
  end
  if $lark_env.global_machine_outlining_summary_emit || $lark_env.global_machine_outlining_summary_consume
    Lark::Project::ToolChainConfig.global_machine_outlining_list.each { |v| source v }
  end
  if $lark_env.bytest_package
      source 'LarkTracing'
      source 'LarkPerf'
  end

 if $lark_env.local? && (enable_remote_cache || ((ENV["REMOTE_CACHE_ENABLE"] || "") == 'true'))
   if !((ENV["REMOTE_CACHE_ENABLE"] || "") == 'false')
     source_dir "."
   end
 end
end

# 修改这里可以临时覆盖 if_pod.rb 中的PB版本声明，不可提交，详情请点击下面的链接
# https://bytedance.feishu.cn/wiki/wikcnR3KU4tqyuT0Ktdom2lF7ie
# https://bytedance.feishu.cn/wiki/wikcn4cOCZVIPCrgex31yCKsvBc
ENV['TMP_PB_VERSION'] ||= ""

# NOTE: 文件功能分类：
# 该文件中应该只声明App需要的根依赖.
# 需要对版本范围或者特定库被引入后的额外集成依赖, 在`if_pod.rb`里配置后，在podfile里引用

def lark_inhouse_pod
  return unless $lark_env.is_inhouse # inhouse 才可用
  lark_inhouse_feedback_pods
end

# 以下模块是由于引入内测SDK引入的依赖库，不会带到正式环境，
# 如果其他需要引入的库依赖了以下模块请移出该位置，并明确声明依赖.
# 参考文档: https://bytedance.feishu.cn/docs/doccn2quPU8YijE7A9vcyGpJtXg#
def lark_inhouse_feedback_pods
  return unless $lark_env.is_feedback_enable # inhouse、INSTALL_FEEDBACK为True、且非KA才可用

  pod 'LarkFeedback', path: './Libs/LarkFeedback'
  pod 'BDFeedBack', '1.3.2-alpha.4'
  pod 'BDLarkAuth', '1.0.11'
  pod 'LarkSSO', '0.1.8.1-binary'
  pod 'TTFileUploadClient', '1.9.54.1' # 用于录屏、截图上传，要求版本号 ~> 1.9
end

def lark_ka_pod
  # NOTE: 只在 KA 包集成
  if $lark_env.is_ka
    pod 'LarkKAExpiredObserver'
  end
end

def lark_root_dependency
  # NOTE: 理论上这里应该只有模块的依赖，其他的依赖应该都是关联依赖
  # 版本限制推荐集中写在if_pod里
  if $lark_env.testable || $lark_env.is_binary_cache_job || $lark_env.is_lynx_devtool_open
    pod 'LynxDevtool', subspecs: %w[Framework DebugResource ThirdPartyCommon RedBoxFramework Native NativeScript NapiBinding/V8 Krypton]
  end

  if $lark_env.is_oversea
    # 由于合规问题，海外版不能依赖 Quaterback ！
  else
    pod 'Quaterback'
  end
  if $lark_env.is_ka_secsdk
    pod 'SecSDK', subspecs: %w[common ver-ka-hz]
  else
    pod 'SecSDK'
  end
  if $lark_env.bytest_autoLogin
    pod 'AAFastbotTweak', subspecs: %w[
      Core
      AutoLogin
    ]
  end
  if $lark_env.code_coverage_enable
    pod 'BDCodeCoverageCollectTool'
    pod 'LarkCodeCoverage'
  end
  if $lark_env.offline_coverage_enable
    pod 'BDTestCoverage'
    script_phase :name=>"Config Test Coverage", :script=>"sh ${PODS_ROOT}/BDTestCoverage/BDTestCoverage/Scripts/git_info.sh --project_id \"${WORKFLOW_REPO_ID}\" --branch \"${WORKFLOW_REPO_BRANCH}\" --hash \"${WORKFLOW_REPO_COMMIT}\" --build_task_id \"${TASK_ID}\"", :execution_position=>:before_compile  end
  unless $lark_env.is_oversea # 海外版不依赖 AMapSearch
  end
  if $lark_env.all_load_cost_enable
    pod 'AllLoadCost'
    pod 'AllStaticInitializerCost'
  end
  pod 'FlameGraphTools', '5.26.0.5262607' if $lark_env.flame_graph_enble
  if $lark_env.testable || $lark_env.is_binary_cache_job
    pod 'TTMLeaksFinder'
    pod 'ByteViewMod', subspecs: ['Debug'], :inhibit_warnings => false
    pod 'ByteViewDebug', :inhibit_warnings => false
    pod 'UDDebug', :inhibit_warnings => false
    # Gecko Debug 头文件存在编译问题，暂时屏蔽
    # pod 'IESGeckoKitDebug', '1.0.15', :subspecs => ['Core']
    pod 'PassportDebug'#, :path => './LarkPassportSDK-iOS/PassportDebug'
  end

  unless $lark_env.is_oversea
    pod 'BulletX'
    pod 'BDXOptimize'
    pod 'BDXContainer', subspecs: %w[Base View Page Popup Util Lynx]
    pod 'BDXRouter'
    pod 'BDXSchema'
  end

  pod 'LarkBoxSettingAssembly'
  pod 'LarkNotificationAssembly'
  pod 'LarkFontAssembly'
  pod 'LarkTabMicroApp'
  pod 'HelpDesk'
  pod 'LarkOpenPlatformAssembly'
  pod 'LarkLynxKit'
  pod 'LarkCreateTeam'
  pod 'MailNativeTemplate'

  pod 'BlockMod'
  pod 'WorkplaceMod'
  pod 'CCMMod'
  pod 'CalendarMod'
  pod 'TodoMod'
  pod 'ByteViewMod', :inhibit_warnings => false
  pod 'MinutesMod', :inhibit_warnings => false
  pod 'LarkLiveMod', :inhibit_warnings => false
  pod 'MessengerMod'
  pod 'LarkMail'
  pod 'MeegoMod'

  pod 'LarkWidgetService'
  pod 'LarkSplash', **$lark_env.oversea({ subspecs: ['overseas'] }, { subspecs: ['domestic'] })
  pod 'LarkSafeMode'
  pod 'LarkBaseService', subspecs: ['Core'], inhibit_warnings: false
  pod 'LarkExtensionAssembly'
  pod 'LarkAssembler'
  pod 'LarkCloudScheme'
  pod 'LarkCrashSanitizer'
  pod 'URLInterceptorManagerAssembly'

  pod 'LarkSecurityCompliance'
  pod 'LarkEMM'

  pod 'LookinServer', configurations: ['Debug']
  pod 'SwiftLint', configurations: ['Debug']
  pod 'LarkVideoDirector'
  pod 'LarkNotificationServiceExtensionLib'
  pod 'LarkMention'
  pod 'LarkIMMention'
  pod 'LarkGeckoTTNet'
  pod 'BDMemoryMatrix'
  pod 'LarkPreloadDependency'
  pod 'LarkEnterpriseNotice'
  pod 'LarkDowngradeDependency'
  pod 'LarkCleanAssembly'
  pod 'lottie-lark'

end

def uploadInfo2Bits
  # 上传组件信息到bits
  if ENV['WORKSPACE'] || ENV.has_key?('CI_JOB_NAME')
    script_phase :name => 'bits_injection', :script => 'export PRODUCT_BUNDLE_IDENTIFIER="com.bytedance.ee.lark";export CURRENT_PROJECT_VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Lark/Info.plist`;export MARKETING_VERSION=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Lark/Info.plist`;env;curl --retry 2 https://ios.bytedance.net/wlapi/tosDownload/iosbinary/d_pod_extentions/6.4.0/bits_component_injection.sh|bash || echo "上传bits组件信息失败"', :execution_position => :before_compile
  end
end

def uploadInfo2Slardar
  # 上传慢函数信息到slardar，目前支持国内灰度包
  if $lark_env.evil_method_enable
    script_phase :name => 'uploadEvilMethodInfo', :script => '/bin/sh ${PODS_ROOT}/Heimdallr/Heimdallr/evilMethodTraceMappingFileUpload.sh CN 462391', :execution_position => :after_compile
  end
end

def dynamic_ka_pods
  if !$lark_env.is_ka?
    return
  end

  #KA需要动态化集成的Pods
  require 'pathname'
  iOS_client_path = File.expand_path('../', Pathname.new(__FILE__).realpath)
  temp_path = File.join(iOS_client_path, 'ka_dynamic_pods')
  native_integration_path = File.join(iOS_client_path, 'bin/ka_resource_replace/native_integration')
  # 需要追加的pods
  if File.exist?(temp_path) && !File.zero?(temp_path)
    File.open(temp_path, 'r') do | file |
      eval file.read
    end
  end

  # 原生集成pods
  if File.exist?(native_integration_path) && !File.zero?(native_integration_path)
    File.open(native_integration_path, 'r') do | file |
      eval file.read
    end
  end

  # 被rust依赖的KA pods，为了避免在rust podspec加默认实现依赖，需要在这里加
  # 需要注意避免有缓存，部分bits插件可能对一些属性加了缓存
  current_non_inherited_dependencies = current_target_definition.non_inherited_dependencies.to_set(&:root_name)
  ['LarkKAFKMS']
    .select { |ka_pod| !current_non_inherited_dependencies.include? ka_pod }
    .each { |ka_default| pod ka_default }
end

enable_local_if_pod # 主仓local pod定义生效, 子仓不生效
target 'Lark' do
  pod 'LarkNotificationContentExtension'
  pod 'NotificationUserInfo'
  pod 'LarkPageIn'
  lark_main_target_if_pods
  lark_root_dependency
  lark_ka_pod
  dynamic_ka_pods
  lark_inhouse_pod
  uploadInfo2Bits
  uploadInfo2Slardar
end

def extension_service_dependency
  pod 'LarkExtensionServices'
end

def extension_network_dependency
  pod 'LarkHTTP'
  extension_service_dependency
end

target 'ShareExtension' do
  pod 'LarkShareExtension', :path => './Libs/LarkShareExtension', :inhibit_warnings => false
  extension_service_dependency
end

target 'BroadcastUploadExtension' do
  pod 'ByteViewBoardcastExtension', '5.30.0.5410491'
  pod 'ByteRtcScreenCapturer'
end

target 'NotificationServiceExtension' do
  $Heimdallr_subspecs = [
    'HMDDyldExtension'
  ]
  if $lark_env.extension_crash_tracker_enable
    $Heimdallr_subspecs.append('CrashDetector')
    $Heimdallr_subspecs.append('DeviceInfo')
  end
  pod 'HeimdallrForExtension', '0.0.2-alpha.9', subspecs: $Heimdallr_subspecs
  pod 'LarkNotificationServiceExtension', :inhibit_warnings => false
  pod 'NotificationUserInfo'
  # FIXME: Podfile指定subspec可以覆盖if_pod里的定义，但这个是跟着target走的..
  # 另外使用pod定义的subspec没有覆盖，需要更完善的集成覆盖方案..
  extension_service_dependency
  pod 'LarkLocalizations'
end

target 'NotificationContentExtension' do
  # FIXME: Podfile指定subspec可以覆盖if_pod里的定义，但这个是跟着target走的..
  # 另外使用pod定义的subspec没有覆盖，需要更完善的集成覆盖方案..
  extension_network_dependency
  pod 'LarkNotificationContentExtension', '5.30.0.5410491'
  pod 'LarkNotificationContentExtensionSDK', '5.30.0.5410491'
  pod 'LarkLocalizations'
  if $lark_env.extension_crash_tracker_enable
    pod 'HeimdallrForExtension', '0.0.2-alpha.9', subspecs: ['CrashDetector','DeviceInfo','HMDDyldExtension']
  end
  pod 'MMKVAppExtension'
end

target 'SmartWidgetExtension' do
  pod 'LarkWidget', '5.30.0.5410491'
  pod 'ByteViewWidget', '0.1.0-alpha.0'
  extension_network_dependency
end

target 'IntentsExtension' do
  pod 'LarkWidget', '5.30.0.5410491'
  pod 'LarkNotificationContentExtensionSDK', '5.30.0.5410491'
  extension_network_dependency
end

target 'LarkAppIntents' do
  extension_network_dependency
end

load_arch_group = lambda do
  return if $lark_env.is_ka? # KA环境比较多变，暂时先不做标记和检测

  ENV['CHECK_ARCH_DEPS'] ||= '1' # 触发架构依赖关系检测
  # load arch group info
  group_orders = %w[layer biz layer-im biz-im]
  pod_group_order_by_keys(group_orders)

  arch = YAML.load_file(File.expand_path("config/arch.yml", __dir__))
  $lark_env.check_arch_rules = arch["RULES"]
  info = arch["ARCH"]

  groups_from_path = lambda do |path|
    path.split(",").to_h do |mark|
      key, value = mark.split("=", 2).map(&:strip)
      value = true if value.nil? # 没有设置value，默认为true
      [key, value]
    end
  end
  info.each do |path, pods|
    next unless pods.is_a? Array
    pod_group(pods, groups_from_path[path])
  end
end
load_arch_group.call

# @param installer [Pod::Installer]
pre_install do |installer|
  raise "lark target should be first!" unless installer.aggregate_targets.first.target_definition.name == "Lark"

  # 根据引入的所有 podspec，校验 Owner 配置
  validate_owner_config!(installer.analysis_result.specifications)

  # 确保LarkSettings自动生成key的文件在pod install时存在
  Lark::Project::LarkSetting.ensure_auto_user_setting_keys_exists

  # reuse same lark_project, to avoid changes be overwrite by cocoapod
  # @type [Xcodeproj::Project, Object]
  $lark_project = installer.aggregate_targets.find { |t| break t.user_project if t.user_project.root_object.name == "Lark" }

  def filter(condition, target_name: "Lark", config_name: "Release", &operation)
    config = $lark_project
      &.targets
      &.find { |target| target.name == target_name }
      &.build_configurations
      &.find { |config| config.name == config_name } if condition

    operation.call(config) if config
  end

  #NotificationServiceExtension添加宏，用来判断是否添加崩溃上报。
  filter($lark_env.extension_crash_tracker_enable, target_name: 'NotificationServiceExtension') { |config|
    config.build_settings['OTHER_SWIFT_FLAGS'] ||= ''
    config.build_settings['OTHER_SWIFT_FLAGS'] += ' -D CRASH_TRACKER_ENABLE'
  }

  #static iniailizer符号化需要设置此编译选项
  filter($lark_env.all_load_cost_enable) { |config|
    config.build_settings['DEPLOYMENT_POSTPROCESSING'] = 'NO'
  }

  filter(ENV['BYTEST_MEMORY_CHECK'].to_s == 'true') { |config|
    config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'NO'
  }

  Lark::Project::ToolChainManager.instance.config_evil_method($lark_project)
  Lark::Project::ToolChainManager.instance.config_zip_text_ld($lark_project)
  fix_offline_coverage($lark_project)
  Dir.chdir(File.expand_path("fastlane", __dir__)) do
    def sh(*args)
      raise "#{args} exec failed!" unless system(*args) == true
    end
    # replace image resource for lark or after pod install
    if $lark_env.is_oversea
      sh "../bin/replace_resource_for_international"
    end
  end

  if $lark_env.is_ka?
    begin
      require_relative 'bin/ka_resource_replace/replace_ka_i18n.rb'
      resource_replacer = KAResource::ReplaceI18N.new
      resource_replacer.run!
    rescue => e
      puts "Error executing ka_resource_replace script: #{e}"
      puts e.backtrace
    end
  end
  
  testable = $lark_env.testable
  # NOTE: 改Sandbox在重新Install时不会重新下载. xcconfig的flag只保证重新生成工程
  require_relative 'bin/i18n/strip_langs.rb'
  if ENV['PSEUDO'] == '1'
    # NOTE: pseudo patch是基于en-US的文案，压缩后重新运行的话，这个文案已经没有了
    load(File.expand_path('bin/pseudo_i18n.rb', __dir__))
    # TODO: Feishu应该是:strip, :compress #
    StripLangs.new(__dir__, [:compress]).run!
    # 这个值其实不是很管用，只能控制project的重新生成，但不能让沙盒重新下载...
    stripped_unneeded_languages = 'compress'
  else
    if ENV['I18N_PATCH'] == '1'
      require_relative 'bin/i18n/patch.rb'
      patch = I18n::Patch.new strict: false # 如果不能更新的模块要抛错，改为true
      patch.update! if ENV['I18N_PATCH_UPDATE'] == '1'
      patch.patch! # 使用本地目录里i18n数据，替换所有的i18n文案
    end
    strategy = []
    strategy.push(:strip) if $lark_env.should_strip_lang
    strategy.push(:meta) if testable # will use meta to show origin i18n Key
    strategy.push(:compress) if $lark_env.should_compress_i18n
    unless strategy.empty?
      I18n::StripLangs.new(__dir__, strategy, installer: installer).run!
      stripped_unneeded_languages = strategy.first.to_s
    end
  end

  lark_template_common_pre_install installer

  # 失效二进制自动升级
  save_binary_list(installer, __dir__) if $lark_env.ci?

  # additional xcconfig
  installer.pod_targets.each do |pod_target|

    pod_target_xcconfig = pod_target.root_spec.attributes_hash['pod_target_xcconfig']

    pod_target_xcconfig['ASSETCATALOG_COMPILER_OPTIMIZATION'] = 'space'
    pod_target_xcconfig['CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED'] = 'NO'

    # DevCare 环境运行参数
    if ENV['DEV_CARE_ENABLE'] == 'true'
      pod_target_xcconfig['CLANG_MODULES_PRUNE_INTERVAL'] = '0' # turn off prune module cache
      pod_target_xcconfig['CLANG_MODULES_PRUNE_AFTER'] = '2592000' # 30 days
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -assert-config Release' # disable swift assert, but assertFailure, precondition, preconditionFailure, fatalError
      pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] += ' NDEBUG NS_BLOCK_ASSERTIONS=0' # disable objc & system assert
    end

#    if @add_inhouse_macro_list.include? pod_target.name
#      pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] ||= '$(inherited)'
#      pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' INHOUSE'
#    end

    pod_target_xcconfig['PSEUDO'] = '2' if ENV['PSEUDO'] == '1'
    pod_target_xcconfig['STRIP_LANG'] = stripped_unneeded_languages if stripped_unneeded_languages

    # 工具链相关配置，热修复、慢函数、覆盖率
    Lark::Project::ToolChainManager.instance.pre_install_config(pod_target)
    #线下代码覆盖率
    if $lark_env.offline_coverage_enable
      if $lark_env.model_mr_list.include?(pod_target.name)
        puts 'offlinecoverage '+pod_target.name
        if !Lark::Project::ToolChainConfig.offline_coverage_for_bid.include?(pod_target.name)
          puts 'offlinecoveraged '+pod_target.name
          pod_target_xcconfig['CLANG_COVERAGE_MAPPING'] = 'YES'
          pod_target_xcconfig['CLANG_ENABLE_CODE_COVERAGE'] = 'YES'
          pod_target_xcconfig['OTHER_CFLAGS'] += ' -fprofile-instr-generate -fcoverage-mapping'
          pod_target_xcconfig['OTHER_LDFLAGS'] += ' -fprofile-instr-generate'
          pod_target_xcconfig['SWIFT_COMPILATION_MODE'] = 'singlefile'
          pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -profile-generate -profile-coverage-mapping'
        end
      end
    end

    # NSE 需要解决系统通话时收到通知增强导致通话音频打断无法恢复的 bug，通过 callkit 库获取是否有进行中的电话进行避免
    if pod_target.name == 'LarkNotificationServiceExtension' && $lark_env.is_callkit_enable
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] ||= ''
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -D CALLKIT_ENABLE'
      pod_target_xcconfig['OTHER_LDFLAGS'] ||= ''
      pod_target_xcconfig['OTHER_LDFLAGS'] += ' -framework "CallKit"'
    end

    # ld-prime链接MMKV动态库会崩溃，强制所有pod_target 都设置ld64，静态库此项无效，动态库会切ld64
    if pod_target_xcconfig['OTHER_LDFLAGS'].nil?
      pod_target_xcconfig['OTHER_LDFLAGS'] = '-ld_classic'
    else
      pod_target_xcconfig['OTHER_LDFLAGS'] += ' -ld_classic'
    end

    # 强制所有pod_target 都禁用mergeable_library, ld64不支持此feature
    pod_target_xcconfig['MERGEABLE_LIBRARY'] = 'NO'
    pod_target_xcconfig['MERGED_BINARY_TYPE'] = 'none'

    # if pod_target.name == 'LarkRustClient'
    #   pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] ||= '$(inherited)'
    #   pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] += ' DisableAssertMain'
    # end
    # bytest打包
    if $lark_env.bytest_package && ['LarkTracing', 'LarkPerf', 'MailSDK'].include?(pod_target.name)
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] ||= ''
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -D IS_BYTEST_PACKAGE'
    end

    if $lark_env.is_ka && pod_target.name == 'LarkReleaseConfig' && ENV['BUILD_PRODUCT_TYPE'] == 'KA'
      # KA 构建时，BUILD_PRODUCT_TYPE取值范围: KA —— Base 飞书， KA_international —— Base Lark
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] ||= ''
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -D IS_BASED_FEISHU'
    end

    if $lark_env.is_binary_cache_job
      pod_target_xcconfig['ENABLE_BITCODE'] = 'NO'
      pod_target_xcconfig['SWIFT_SERIALIZE_DEBUGGING_OPTIONS'] = 'NO'
      pod_target_xcconfig['SWIFT_COMPILATION_MODE'] = 'singlefile'
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -Xfrontend -no-serialize-debugging-options'
    end

    # LynxDevtool：lynx devtool开放给block开发者
    if $lark_env.is_lynx_devtool_open && ['OPBlock', 'LarkWorkplace', 'LarkOpenPlatformAssembly'].include?(pod_target.name)
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] ||= ''
      pod_target_xcconfig['OTHER_SWIFT_FLAGS'] += ' -D IS_LYNX_DEVTOOL_OPEN'
    end

    # RN Debug
    if pod_target.name == 'React-Core' && ENV['ENABLE_RN_DEBUG'] == 'true'
      pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] ||= ''
      pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] += ' ENABLE_RN_DEBUG=1 '
    end
  end
end

# @param installer [Pod::Installer]
post_install do |installer|
  # the post installer change won't mark cache invalid, and the results is not full(unless use clean install)
  # but it can set config by configurations...

  warn_as_error = $lark_env.can_change_module_stability && { 'Debug' => $lark_env.treat_warning_as_errors_list }
  lark_template_common_post_install(installer, warn_as_error: warn_as_error)
  # KA环境下对三方库开启接口稳定
  if $lark_env.is_ka
    arch = YAML.load_file(File.expand_path("config/arch.yml", __dir__))
    ka_alchemy_list = arch['KA']['layer=ka-alchemy, biz=component']
    installer.pod_targets.each do |target|
      if ka_alchemy_list.include? target.name
          target.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end
  end

  installer.target_installation_results.pod_target_installation_results.each do |name, result|
    # @type [Xcodeproj::Project::Object::PBXNativeTarget]
    target = result.native_target
    release_settings = target.build_settings('Release')
    # if !$lark_env.testable
    #   # lto会影响linkmap符号影响模块体积分析,只在appstore下打开lto
    if $lark_env.lto_enable
      # 因为Apple的LTO有bug，临时关闭LynxDevtool的LTO，修复后再打开
      if name == 'LynxDevtool'
        puts "[LARKLTO] skip LTO #{name}"
      else
        puts "[LARKLTO] Applying LTO #{name}"
        release_settings['LLVM_LTO'] = 'YES'
      end
    end

    release_settings['SWIFT_OPTIMIZATION_LEVEL'] = ($lark_env.is_binary_cache_job ? '-O' : '-Osize')
    release_settings['GCC_OPTIMIZATION_LEVEL'] = 'z'

    # 最终由ToolChainManager确定配置
    Lark::Project::ToolChainManager.instance.post_install_config(name, release_settings)
  end

  Lark::Project::LarkSetting.run

  # 打印当前的环境变量和toolchain信息
  Lark::Project::ToolChainManager.instance.snapshot_current_state unless $lark_env.local?
end

# rubocop:enable all
