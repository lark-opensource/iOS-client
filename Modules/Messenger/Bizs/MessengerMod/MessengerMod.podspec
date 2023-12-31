# frozen_string_literal: true

#
# Be sure to run `pod lib lint MessengerMod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'MessengerMod'
  s.version = '5.31.0.5424672'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    name: 'email'
  }

  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.resource_bundles = {
    'MessengerMod' => ['resources/*'],
    'MessengerModAuto' => 'auto_resources/*'
  }

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'
  eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

  s.default_subspecs = 'Core'
  s.subspec 'Core' do |sp|
    sp.dependency 'LarkAccount'
    sp.dependency 'LarkSDK'
    sp.dependency 'LarkSendMessage'
    sp.dependency 'LarkNavigation'
    sp.dependency 'LarkFeedPlugin'
    sp.dependency 'LarkFlag'
    sp.dependency 'LarkUrgent'
    sp.dependency 'LarkFinance'
    sp.dependency 'LarkChat'
    sp.dependency 'LarkFile'
    sp.dependency 'LarkThread'
    sp.dependency 'LarkContact'
    sp.dependency 'LarkSearch'
    sp.dependency 'LarkChatSetting'
    sp.dependency 'LarkQRCode'
    sp.dependency 'LarkWaterMark'
    sp.dependency 'LarkFocus'
    sp.dependency 'LarkVersion'
    sp.dependency 'LarkGuide'

    sp.dependency 'RunloopTools'
    sp.dependency 'LarkMonitor'
    sp.dependency 'LarkShareToken'
    sp.dependency 'BootManager'
    sp.dependency 'LKContentFix'
    sp.dependency 'LarkAI'
    sp.dependency 'HelpDesk'
    sp.dependency 'LarkMessengerInterface'
    sp.dependency 'Moment'
    sp.dependency 'LarkShareContainer'
    sp.dependency 'LarkKAFeatureSwitch'
    sp.dependency 'LarkKeyCommandKit/Extensions'
    sp.dependency 'ByteWebImage'
    sp.dependency 'LarkMinimumMode'
    sp.dependency 'LarkTeam'

    sp.dependency 'SuiteAppConfig/Core'
    sp.dependency 'SuiteAppConfig/Assembly'
    sp.dependency 'LarkEmotion/Core'
    sp.dependency 'LarkEmotion/Assemble'
    sp.dependency 'LarkSetting/Core'
    sp.dependency 'LarkSetting/LarkAssemble'
    sp.dependency 'ByteWebImage/Core'
    sp.dependency 'ByteWebImage/Lark'
    sp.dependency 'LarkAssembler'
    sp.dependency 'LKLoadable'
    sp.dependency 'LarkInteraction'
    sp.dependency 'LarkSensitivityControl/API/DeviceInfo'
    sp.dependency 'LarkMine'
    sp.dependency 'LarkClean'
    sp.dependency 'CTADialog/Core'

    sp.source_files = 'src/**/*.{swift}'
    sp.exclude_files = 'src/MessengerPlugins/**/*'
  end
  # 规范: 条件依赖的插件代码都放到MessengerPlugins里，第一层目录是功能名，后面是对应的各个业务扩展的功能. 文件名统一业务前缀..
  s.if_pod 'CalendarMod' do |cs|
    cs.dependency 'Calendar'
    cs.source_files = 'src/MessengerPlugins/*/Calendar*.swift'
  end

  s.if_pod 'ByteViewMod' do |cs|
    cs.dependency 'ByteViewInterface'
  end

  s.if_pod 'TodoMod' do |cs|
    cs.dependency 'TodoInterface'
    cs.source_files = 'src/MessengerPlugins/*/Todo*.swift'
  end

  s.if_pod 'CCMMod' do |cs|
    cs.dependency 'SKDrive'
    cs.dependency 'SKSpace'
    cs.dependency 'CCMMod'
    cs.dependency 'SpaceInterface'
    cs.source_files = 'src/MessengerPlugins/*/{Doc,Bitable}*.swift'
  end
  
  s.if_pod 'LarkCore' do |cs|
    cs.dependency 'LarkCore'
    cs.dependency 'LarkBaseKeyboard/Transformers'
  end

  s.if_pod 'LarkOpenPlatform' do |cs|
    cs.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'GagetMod' }
    cs.dependency 'LarkOPInterface'
    cs.dependency 'EEMicroAppSDK'
    cs.dependency 'LarkFeatureGating'
    cs.source_files = 'src/MessengerPlugins/*/MicroApp*.swift'
  end

  s.if_pod 'LarkMail' do |cs|
    cs.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'MailMod' }
    cs.dependency 'LarkMail'
    cs.dependency 'LarkMailInterface'
  end

  s.if_pod 'MeegoMod' do |cs|
    cs.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'MeegoMod' }
    cs.dependency 'LarkMeegoInterface'
    cs.source_files = 'src/MessengerPlugins/*/WorkItemNormalChatKeyboardSubModule.swift'
  end

  attributes_hash = s.instance_variable_get(:@attributes_hash)
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    git_url: 'Required.'
  }
end
