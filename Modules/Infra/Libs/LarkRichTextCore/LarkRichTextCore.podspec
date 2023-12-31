Pod::Spec.new do |s|
    s.name          = 'LarkRichTextCore'
    s.version = '5.31.0.5471505'
    s.author        = { 'Arthur Li' => 'lichen.arthur@bytedance.com' }
    s.license       = 'MIT'
    s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkCore'
    s.summary       = 'Core business moudule for Lark'
    s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkBusinessModule', :tag => s.version.to_s }

    s.preserve_paths = 'configurations/**/*'
    s.platform      = :ios
    s.ios.deployment_target = "11.0"
    s.swift_version = "5.1"

    s.subspec 'Base' do |ss|
      ss.source_files = 'src/{Icon,configurations}/**/*.{swift,h,m}'

      ss.resource_bundles = {
        'LarkRichTextCore' => ['resources/*'],
        'LarkRichTextCoreAuto' => ['auto_resources/*'],
      }
      ss.dependency 'RustPB'
      ss.dependency 'LarkLocalizations'
      ss.dependency 'UniverseDesignIcon'
    end

    s.subspec 'Main' do |ss|
      ss.source_files = 'src/{Source}/**/*.{swift,h,m}'

      ss.dependency 'SnapKit'
      ss.dependency 'RustPB'
      ss.dependency 'LarkFoundation'
      ss.dependency 'RxSwift'
      ss.dependency 'LarkUIKit'
      ss.dependency 'LarkModel'
      ss.dependency 'LarkFeatureGating'
      ss.dependency 'EENavigator'
      ss.dependency 'LKCommonsLogging'
      ss.dependency 'LKCommonsTracker'
      ss.dependency 'LarkEmotion'
      ss.dependency 'EditTextView'
      ss.dependency 'LarkLocalizations'
      ss.dependency 'LarkResource'
      ss.dependency 'ByteWebImage/Core'
      ss.dependency 'ByteWebImage/Lark'
      ss.dependency 'UniverseDesignEmpty'
      ss.dependency 'LKRichView/Core'
      ss.dependency 'LarkRichTextCore/Base'
    end


end
