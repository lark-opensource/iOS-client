# frozen_string_literal: true

#
# Be sure to run `pod lib lint ByteViewMod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'ByteViewMod'
  s.version = '5.31.0.5477762'
  s.summary          = 'ByteView集成层组件'
  s.description      = 'ByteView集成层组件'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "kiri": 'dengqiang.001@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/*.{swift}'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'

  eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

  s.subspec 'configurations' do |cs|
    cs.source_files = ['src/configurations/*.{swift}']
    cs.resource_bundles = {
      'ByteViewMod' => ['resources/Assets.xcassets', 'resources/*.xcprivacy'],
      'ByteViewModAuto' => ['auto_resources/**/*']
    }

    cs.dependency 'LarkLocalizations'
    cs.dependency 'LarkResource'
  end

  s.subspec 'Core' do |cs|
    cs.source_files = ['src/Core/**/*.{swift,h,m}']
    cs.dependency 'ByteViewMod/configurations'
    cs.dependency 'ByteView'
    cs.dependency 'ByteViewCommon'
    cs.dependency 'ByteViewInterface'
    cs.dependency 'ByteViewTracker'
    cs.dependency 'ByteViewNetwork'
    cs.dependency 'ByteViewWidgetService'
    cs.dependency 'ByteViewSetting'
    cs.dependency 'ByteViewLiveCert'

    cs.dependency 'AppContainer'
    cs.dependency 'ByteWebImage'
    cs.dependency 'BootManager'
    cs.dependency 'EENavigator'
    cs.dependency 'Homeric'
    cs.dependency 'NotificationUserInfo'
    cs.dependency 'RustPB'

    cs.dependency 'LKLoadable'
    cs.dependency 'LarkAccountInterface'
    cs.dependency 'LarkReleaseConfig'
    cs.dependency 'LarkRustClient'
    cs.dependency 'LarkEmotion'
    cs.dependency 'LarkEmotionKeyboard'
    cs.dependency 'LKCommonsLogging'
    cs.dependency 'LKCommonsTracker'
    cs.dependency 'LarkSetting'
    cs.dependency 'LarkAssembler'
    cs.dependency 'LarkTTNetInitializor'
    cs.dependency 'LarkPushCard'
    cs.dependency 'LarkContainer'
    cs.dependency 'UniverseDesignLoading'
    cs.dependency 'LarkUIKit'
    cs.dependency 'LarkBizAvatar'
    cs.dependency 'LarkSuspendable'
    cs.dependency 'LarkNavigation'
    cs.dependency 'LarkAppLinkSDK'
    cs.dependency 'LarkStorage'
    cs.dependency 'LarkDocsIcon'
    cs.dependency 'EENavigator'

    cs.dependency 'LarkDowngrade'
  end

  s.subspec 'Hybrid' do |cs|
    cs.source_files = ['src/Hybrid/**/*.{swift}']
    cs.pod_target_xcconfig = {'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'HybridMod'}
    cs.dependency 'ByteViewMod/Core'
    cs.dependency 'ByteView/Hybrid'
    cs.dependency 'OfflineResourceManager'
  end

  s.subspec 'CallKit' do |cs|
    cs.source_files = ['src/CallKit/**/*.{swift}']
    cs.pod_target_xcconfig = {'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'CallKitMod'}
    cs.dependency 'ByteViewMod/Core'

    cs.dependency 'ByteView/CallKit'
  end

  s.subspec 'Tab' do |cs|
    cs.source_files = ['src/Tab/**/*.{swift}']
    cs.pod_target_xcconfig = {'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'TabMod'}
    cs.dependency 'ByteViewMod/Core'

    cs.dependency 'ByteViewTab'
  end

  s.subspec 'Lark' do |cs|
    cs.source_files = ['src/Lark/**/*.{swift}']
    cs.pod_target_xcconfig = {'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'LarkMod'}
    cs.dependency 'ByteViewMod/Core'
    cs.dependency 'ByteViewMod/Tab'
    cs.dependency 'ByteViewMod/Hybrid'

    cs.dependency 'Heimdallr'
    cs.dependency 'LarkPerf'
    cs.dependency 'LarkBytedCert'
    cs.dependency 'LarkPushTokenUploader'
    cs.dependency 'LarkRVC'
    cs.dependency 'LarkBytedCert'
    cs.dependency 'LarkWaterMark'
    cs.dependency 'LarkVersion'
    cs.dependency 'LarkAssetsBrowser'
    cs.dependency 'LarkSplitViewController'
    cs.dependency 'AnimatedTabBar'
    cs.dependency 'LarkSecurityComplianceInterface'
    cs.dependency 'LarkSettingUI'
    cs.dependency 'LarkOpenSetting'
    cs.dependency 'LarkEMM'
    cs.dependency 'LarkMonitor'
    cs.dependency 'LarkGuide'
    cs.dependency 'LarkSensitivityControl/API/Pasteboard'
    cs.dependency 'LarkCustomerService'
  end

  s.subspec 'Debug' do |cs|
    cs.dependency 'ByteViewDebug'
  end

  # 对其他业务线的依赖，使用if_pod语法
  s.if_pod 'MessengerMod' do |cs|
    cs.source_files = ['src/Messenger/**/*.{swift}']
    cs.dependency 'ByteViewMod/Core'

    cs.dependency 'ByteViewMessenger'
    cs.dependency 'LarkForward'
    cs.dependency 'LarkMessengerInterface'
    cs.dependency 'LarkSDKInterface'
    cs.dependency 'LarkSendMessage'
    cs.dependency 'LarkFocus'
    cs.dependency 'LarkBaseKeyboard/Transformers'
    cs.dependency 'LarkRichTextCore'
    cs.dependency 'LarkSearchCore'
    cs.dependency 'LarkNavigator'
    cs.dependency 'LarkAIInfra'
  end

  s.if_pod 'CCMMod' do |cs|
    cs.source_files = ['src/CCM/**/*.{swift}']
    cs.dependency 'ByteViewMod/Core'
    cs.dependency 'SpaceInterface'
  end

  s.if_pod 'MinutesMod' do |cs|
    cs.source_files = ['src/Minutes/**/*.{swift}']
    cs.dependency 'ByteViewMod/Core'
    cs.dependency 'MinutesInterface'
    cs.dependency 'MinutesNavigator'
  end

  s.if_pod 'LarkLiveMod' do |cs|
    cs.source_files = ['src/Live/**/*.{swift}']
    cs.dependency 'ByteViewMod/Core'
    cs.dependency 'LarkLiveInterface'
  end

  s.if_pod 'CalendarMod' do |cs|
    cs.source_files = ['src/Calendar/**/*.{swift}']
    cs.dependency 'ByteViewMod/Core'

    cs.dependency 'ByteViewCalendar'
    cs.dependency 'Calendar'
    cs.dependency 'CalendarFoundation'
    cs.dependency 'CalendarRichTextEditor'
  end

  s.default_subspecs = ['Lark']

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'Required.'
  }
end
