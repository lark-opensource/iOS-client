# coding: utf-8
Pod::Spec.new do |s|
    s.name = 'LarkVersion'
    s.version = '5.30.0.5410491'
    s.author = { "name": 'liuxianyu@bytedance.com' }
    s.license = 'MIT'
    s.homepage = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkVersion'
    s.summary = '版本升级相关'
    s.source = {:git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkVersion', :tag => s.version.to_s}
  
    s.platform = :ios
    s.ios.deployment_target = "11.0"
    s.swift_version = "5.1"

    s.dependency 'RxSwift'
    s.dependency 'RxCocoa'
    s.dependency 'LarkFoundation'
    s.dependency 'LarkUIKit'
    s.dependency 'LarkModel'
    s.dependency 'LarkReleaseConfig'
    s.dependency 'LarkSetting'
    s.dependency 'LKCommonsLogging'
    s.dependency 'LarkSDKInterface'
    s.dependency 'LarkContainer'
    s.dependency 'RustPB'
    s.dependency 'EENavigator'
    s.dependency 'LarkAccountInterface'
    s.dependency 'LarkAppConfig'
    s.dependency 'LarkStorage/KeyValue'
    s.dependency 'LKCommonsTracker'
    s.dependency 'Homeric'
    s.dependency 'LarkAssembler'
    s.dependency 'LarkDialogManager'
    s.dependency 'LarkNavigator'
    s.dependency 'UniverseDesignDialog'
    s.dependency 'FigmaKit'
  
    s.source_files =  'src/**/*.swift'
    s.resource_bundles = {
        'LarkVersion' => ['resources/*'],
        'LarkVersionAuto' => ['auto_resources/*']
    }
    s.preserve_paths = 'configurations/**/*'
end
