
# 引入if_pod语法扩展
eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

Pod::Spec.new do |s|
  s.name = 'LarkMail'
  s.version = '5.31.0.5483980'
  s.author = { "tanzhiyuan" => "tanzhiyuan@bytedance.com" }
  s.license = 'MIT'
  s.homepage = 'git@code.byted.org:ee/mail-ios-client.git'
  s.summary = 'Lark Mail Module'
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd", :tag => s.version.to_s}

  s.platform = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.3"

  s.dependency 'LarkLocalizations'
  s.dependency 'SnapKit'
  s.dependency 'RxSwift'
  s.dependency 'RxRelay'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkModel'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkRustHTTP'
  s.dependency 'LarkRustClient'
  s.dependency 'Swinject'
  s.dependency 'LarkContainer'
  s.dependency 'MailSDK'
  s.dependency 'EENavigator'
  s.dependency 'LarkAppResources'
  s.dependency 'LKCommonsTracker'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkTimeFormatUtils'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkAppConfig'
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'LarkDebugExtensionPoint'
  s.dependency 'LarkNavigation'
  s.dependency 'OfflineResourceManager'
  s.dependency 'LarkMailInterface'
  s.dependency 'LarkGuide'
  s.dependency 'WebBrowser'
  s.dependency 'LarkWaterMark'
  s.dependency 'ByteWebImage'
  s.dependency 'LarkExtensionCommon'
  s.dependency 'LarkAssembler'
  s.dependency 'LKLoadable'
  s.dependency 'LarkSetting'
  s.dependency 'LarkSDKInterface'
  s.dependency 'LarkStorage'
  s.dependency 'LarkOpenSetting'
  s.dependency 'LarkQRCode'
  s.dependency 'LarkPreload'
  s.dependency 'LarkOpenFeed'
  s.dependency 'LarkFeedBase'
  s.dependency 'LarkAIInfra'
  s.if_pod 'MessengerMod' do |cs|
    cs.pod_target_xcconfig = {'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'MessengerMod'}
    cs.dependency 'LarkMessengerInterface'
    cs.dependency 'LarkCore'
    cs.dependency 'LarkForward'
  end

  s.if_pod 'CalendarMod' do |cs|
    cs.pod_target_xcconfig = {'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'CalendarMod'}
    cs.dependency 'Calendar'
  end

  s.if_pod 'CCMMod' do |cs|
    cs.pod_target_xcconfig = {'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'CCMMod'}
    cs.dependency 'SpaceInterface'
  end

  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  s.resource_bundles = {
    'LarkMail' => ['resources/*'] ,
    # 'LarkMailAuto' => 'auto_resources/*'
  }
  s.preserve_paths = 'configurations/**/*'
end
