Pod::Spec.new do |s|
  s.name          = 'LarkUrgent'
  s.version = '5.30.0.5410491'
  s.author        = { 'Liu Wanlin' => 'liuwanlin@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkUrgent'
  s.summary       = 'Urgent business moudule for Lark'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkBusinessModule', :tag => s.version.to_s }
  s.resource_bundles = {
    'LarkUrgent' => ['resources/*'],
    'LarkUrgentAuto' => ['auto_resources/*']
  }
  s.preserve_paths = 'configurations/**/*'
  s.platform      = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  s.dependency 'LarkCore'
  s.dependency 'SnapKit'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkUIKit'
  s.dependency 'RxSwift'
  s.dependency 'LarkModel'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkContainer'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'SuiteAppConfig'
  s.dependency 'BootManager'
  s.dependency 'LarkListItem'
  s.dependency 'LarkSceneManager'
  s.dependency 'LarkSuspendable'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'LarkBizAvatar'
  s.dependency 'LarkExtensions'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkOpenFeed'
  s.dependency 'LarkPushCard'
  s.dependency 'LKWindowManager'
  s.dependency 'LarkBizTag'
  s.dependency 'LarkOpenSetting'
  s.dependency 'ServerPB'
  s.dependency 'CTADialog/Core'

  s.default_subspec = ['Core', 'EMC']

  s.subspec 'Core' do |sub|
    sub.source_files = 'src/{Config,configurations,Tracker,Urgent}/**/*.swift'
  end

  s.subspec 'EMC' do |sub|
    sub.source_files = 'src/EM/EMCore/**/*.swift'
  end

  s.subspec 'EMD' do |sub|
    sub.source_files = 'src/EM/EMData/**/*.swift'
    sub.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D IS_EM_ENABLE' }
  end
end
