Pod::Spec.new do |s|
    s.name          = 'LarkKeyboardView'
    s.version = '5.31.0.5475597'
    s.author        = { 'Arthur Li' => 'lichen.arthur@bytedance.com' }
    s.license       = 'MIT'
    s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkCore'
    s.summary       = 'Core business moudule for Lark'
    s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkBusinessModule', :tag => s.version.to_s }
    s.source_files  = 'src/**/*.{swift,h,m}'
    s.resource_bundles = {
        'LarkKeyboardView' => ['resources/*'],
        'LarkKeyboardViewAuto' => ['auto_resources/*'],
    }
    s.preserve_paths = 'configurations/**/*'
    s.platform      = :ios
    s.ios.deployment_target = "11.0"
    s.swift_version = "5.1"

    s.dependency 'SnapKit'
    s.dependency 'RxSwift'
    s.dependency 'LarkUIKit'
    s.dependency 'LKCommonsLogging'
    s.dependency 'UniverseDesignColor'
    s.dependency 'EditTextView'
    s.dependency 'LarkKeyCommandKit'
    s.dependency 'LarkInteraction'
    s.dependency 'LarkLocalizations'
    s.dependency 'LarkResource'
    s.dependency 'UniverseDesignIcon'
    s.dependency 'UniverseDesignBadge'
    s.dependency 'FigmaKit'
end
