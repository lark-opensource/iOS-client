Pod::Spec.new do |s|
    s.name          = 'LarkCore'
    s.version = '5.32.0.5483844'
    s.author        = { 'Arthur Li' => 'lichen.arthur@bytedance.com' }
    s.license       = 'MIT'
    s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkCore'
    s.summary       = 'Core business moudule for Lark'
    s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkBusinessModule', :tag => s.version.to_s }
    s.source_files  = 'src/**/*.{swift,h,m}'
    s.resource_bundles = {
        'LarkCore' => ['resources/*'],
        'LarkCoreAuto' => ['auto_resources/*'],
    }
    s.preserve_paths = 'configurations/**/*'
    s.platform      = :ios
    s.ios.deployment_target = "11.0"
    s.swift_version = "5.1"

    s.dependency 'SnapKit'
    s.dependency 'LarkFoundation'
    s.dependency 'RxSwift'
    s.dependency 'LarkUIKit'
    s.dependency 'LarkModel'
    s.dependency 'LarkFeatureGating'
    s.dependency 'DateToolsSwift'
    s.dependency 'LarkRustClient'
    s.dependency 'EENavigator'
    s.dependency 'LKCommonsTracker'
    s.dependency 'LKCommonsLogging'
    s.dependency 'LarkTag'
    s.dependency 'LarkMedia'
    s.dependency 'LarkReleaseConfig'
    s.dependency 'EditTextView'
    s.dependency 'QRCode'
    s.dependency 'LarkEmotion'
    s.dependency 'LarkMessageBase'
    s.dependency 'LarkAlertController'
    s.dependency 'LarkAccountInterface'
    s.dependency 'LarkAppConfig'
    s.dependency 'Homeric'
    s.dependency 'LarkRustHTTP'
    s.dependency 'LarkMessengerInterface'
    s.dependency 'LarkFeatureSwitch'
    s.dependency 'LarkStorage/Sandbox'
    s.dependency 'LarkGuide'
    s.dependency 'LarkNavigation'
    s.dependency 'LarkKeyCommandKit'
    s.dependency 'LarkAvatar'
    s.dependency 'LarkAccount'
    s.dependency 'LarkInteraction'
    s.dependency 'LarkSnsShare/Interface'
    s.dependency 'LarkSDKInterface'
    s.dependency 'LarkBizAvatar'
    s.dependency 'LarkListItem'
    s.dependency 'LarkStorage'
    s.dependency 'LarkImageEditor/V1'
    s.dependency 'LarkSetting'
    s.dependency 'LarkQRCode'
    s.dependency 'CookieManager'
    s.dependency 'LarkZoomable'
    s.dependency 'SkeletonView'
    s.dependency 'LarkKAFeatureSwitch'
    s.dependency 'LarkLocalizations'
    s.dependency 'LarkEmotionKeyboard'
    s.dependency 'LarkResource'
    s.dependency 'ThreadSafeDataStructure'
    s.dependency 'UniverseDesignDialog'
    s.dependency 'UniverseDesignFont'
    s.dependency 'ByteWebImage/Core'
    s.dependency 'ByteWebImage/Lark'
    s.dependency 'UniverseDesignCheckBox'
    s.dependency 'UniverseDesignEmpty'
    s.dependency 'LKRichView'
    s.dependency 'TangramService'
    s.dependency 'UniverseDesignIcon'
    s.dependency 'UniverseDesignBadge'
    s.dependency 'FigmaKit'
    s.dependency 'LarkFocusInterface'
    s.dependency 'UniverseDesignLoading'
    s.dependency 'LarkRichTextCore'
    s.dependency 'LarkKeyboardView'
    s.dependency 'LarkShareContainer'
    s.dependency 'UniverseDesignActionPanel'
    s.dependency 'UniverseDesignTabs'
    s.dependency 'LarkAssembler'
    s.dependency 'LarkEMM'
    s.dependency 'LarkOCR'
    s.dependency 'LarkBizTag'
    s.dependency 'LarkSensitivityControl/API/Pasteboard'
    s.dependency 'LarkBaseKeyboard'
    s.dependency 'LarkSendMessage'

    s.test_spec 'Tests' do |test_spec|
        test_spec.test_type = :unit
        test_spec.source_files = 'tests/*.{swift,h,m,mm,cpp}'
        test_spec.pod_target_xcconfig = {
            'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
        }
        test_spec.scheme = {
            :code_coverage => true
        }
    end
end
