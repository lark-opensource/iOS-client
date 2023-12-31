# coding: utf-8
 Pod::Spec.new do |s|
  s.name         = "LarkAccount"
  s.version = '5.32.0.5482716'
  s.summary      = '登录账号管理'
  s.description  = 'LarkAccount for lark'

  s.homepage     = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkAccount'

  s.license      = 'MIT'

  s.author       = { "liuwanlin" => "liuwanlin@bytedance.com" }
  s.source       = { :git => "ssh://git.byted.org:29418/ee/lark/ios-LarkAccount", :tag => "#{s.version}" }

  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.default_subspecs = ['Core']

  s.subspec 'Overall' do |cs|
    cs.dependency 'LarkAccount/Core'
    cs.dependency 'LarkAccount/Authorization'
    cs.dependency 'LarkAccount/IDP'
    cs.dependency 'LarkAccount/RustPlugin'
    cs.dependency 'LarkAccount/NativePlugin'
    cs.dependency 'LarkAccount/OneKeyLogin'
    cs.dependency 'LarkAccount/BootManager'
  end

  s.subspec 'Core' do |cs|
    cs.source_files  = 'src/Source/**/*.{h,m,mm,swift}'

    cs.dependency 'LarkAccount/SuiteLoginCore'
    cs.dependency 'LarkAccount/UI'
    cs.dependency 'SnapKit'
    cs.dependency 'RxSwift'
    cs.dependency 'RxCocoa'
    cs.dependency 'Logger', ">= 1.4.6"
    cs.dependency 'Swinject'
    cs.dependency 'LarkContainer'
    cs.dependency 'EENavigator'
    cs.dependency 'LarkUIKit'
    cs.dependency 'AppContainer'
    cs.dependency 'LarkReleaseConfig'
    cs.dependency 'LarkAlertController'
    cs.dependency 'LarkAccountInterface'
    cs.dependency 'LarkPerf'
    cs.dependency 'LarkDebugExtensionPoint'
    cs.dependency 'LarkSettingsBundle'
    cs.dependency 'RoundedHUD'
    cs.dependency 'RunloopTools'
    cs.dependency 'BootManager'
    cs.dependency 'LarkAppLog'
    cs.dependency 'LarkKAFeatureSwitch'
    cs.dependency 'LarkEnv'
    cs.dependency 'ReachabilitySwift'
    cs.dependency 'ECOProbe'
    cs.dependency 'LarkResource'
    cs.dependency 'LarkIllustrationResource'
    cs.dependency 'LarkAppResources'
    cs.dependency 'LarkIllustrationResource'
    cs.dependency 'LarkAppResources'
    cs.dependency 'LarkAssembler'
    cs.dependency 'LarkTracker'
    cs.dependency 'LarkSensitivityControl/API/DeviceInfo'
    cs.dependency 'LarkEMM'    
    cs.dependency 'LarkOpenSetting'
    cs.dependency 'LarkNavigation'
    cs.dependency 'LarkSensitivityControl/API/Pasteboard'
    cs.dependency 'LarkStorage'
    cs.dependency 'ECOProbeMeta'
    cs.dependency 'LarkFontAssembly'
  end

  # internal impl
  s.subspec 'SuiteLoginCore' do |cs|
    cs.source_files = 'src/SuiteLogin/Classes/**/*.{swift,h,m,mm,cpp}', 'src/SuiteLogin/KeyAccount/Placeholder/**/*.{swift,h,m,mm,cpp}'
    cs.dependency 'LarkAccount/Interface'
    cs.dependency 'LarkAccount/Public'
    cs.dependency 'LarkAccount/Configurations'
    cs.dependency 'LarkAccount/TuringCore'
    cs.dependency 'LarkAccount/SecSDKCommon'

    cs.dependency 'lottie-ios', ' ~> 2.0'
    cs.dependency 'LarkUIKit'
    cs.dependency 'KeychainAccess'
    cs.dependency 'LarkLocalizations'
    cs.dependency 'RoundedHUD'
    cs.dependency 'CryptoSwift'
    cs.dependency 'LarkAlertController'
    cs.dependency 'Homeric'
    cs.dependency 'Kingfisher'
    cs.dependency 'LarkReleaseConfig'
    cs.dependency 'QRCode'
    cs.dependency 'LKTracing'
    cs.dependency 'EENavigator'
    cs.dependency 'LKCommonsLogging'
    cs.dependency 'UniverseDesignActionPanel'
    cs.dependency 'UniverseDesignFont'
    cs.dependency 'UniverseDesignColor'
    cs.dependency 'UniverseDesignStyle'
    cs.dependency 'UniverseDesignTheme'
    cs.dependency 'UniverseDesignProgressView'
    cs.dependency 'UniverseDesignEmpty'
    cs.dependency 'LarkCache'
    cs.dependency 'ECOProbeMeta'
    cs.dependency 'LarkClean'
  end

  # use to declare the exposed class & struct
  # 用于声明对外暴露的类和结构体
  s.subspec 'Public' do |cs|
    cs.source_files = "src/SuiteLogin/Public/**/*.{swift,h,m,mm,cpp}"
  end

  # 用于声明对外暴露的类和结构体
  s.subspec 'bytestAutoLogin' do |cs|
     cs.dependency 'AAFastbotTweak'
     cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D BYTEST_AUTO_LOGIN' }
  end

  # used to declare the exposed interface
  # 用于声明内部的接口
  s.subspec 'Interface' do |cs|
    cs.source_files = 'src/SuiteLogin/KeyAccount/Interface/**/*.{swift,h,m,mm,cpp}', 'src/SuiteLogin/Interface/**/*.{swift,h,m,mm,cpp}', 'src/SuiteLogin/IDP/Interface/**/*.{swift,h,m,mm,cpp}', 'src/InternalInterface/**/*.{swift,h,m,mm,cpp}'
  end

  # One Key Login
  s.subspec 'OneKeyLogin' do |cs|
    cs.source_files = 'src/SuiteLogin/OneKeyLogin/**/*.{swift,h,m,mm,cpp}'
    cs.dependency 'LarkAccount/Core'

    cs.dependency 'BDUGAccountOnekeyLogin'
    cs.dependency 'BDUGUnionSDK'
    cs.dependency 'BDUGContainer'
    cs.dependency 'BDUGMonitorInterface'
    cs.dependency 'BDUGTrackerInterface'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D ONE_KEY_LOGIN' }
  end

  # debug interface use on demo host app, expose internal type
  # debug 接口用于 Demo 宿主应用，用于封装暴露内部实现
  s.subspec 'Debug' do |cs|
    cs.source_files = 'src/SuiteLogin/Debug/**/*.{swift,h,m,mm,cpp}'
    cs.dependency 'LarkAccount/Core'
  end

  # IDP
  s.subspec 'IDP' do |cs|
    cs.source_files = 'src/SuiteLogin/IDP/Implementation/**/*.{swift,h,m,mm,cpp}'

    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D IDP' }

    cs.dependency 'ECOProbeMeta'
  end

  # Google Sign In
  s.subspec 'GoogleSignIn' do |cs|
    cs.dependency 'GoogleSignIn', '5.0.2'

    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D GOOGLE_SIGN_IN' }
  end

  # 图灵验证
  s.subspec 'TuringCore' do |cs|
    cs.source_files = 'src/SuiteLogin/Turing/**/*.{swift,h,m,mm,cpp}'
    
    cs.dependency 'BDTuring/Core'
    cs.dependency 'BDTuring/TTNet'
    cs.dependency 'BDTuring/Localized/EN'
    cs.dependency 'BDTuring/Localized/ZH'
    cs.dependency 'BDTuring/TTNetProcessor'
  end

  # 图灵验证[国内]（安全风控人机滑块验证）
  s.subspec 'TuringCN' do |cs|
    cs.dependency 'BDTuring/Host/CN'
  end

  # 图灵验证[国际]（安全风控人机滑块验证）
  s.subspec 'TuringOversea' do |cs|
    cs.dependency 'BDTuring/Host/SG'
    cs.dependency 'BDTuring/Host/VA'
    cs.dependency 'BDTuring/Host/IN'
  end

  s.subspec 'SecSDKCommon' do |cs|
    cs.dependency 'SecSDK/common'
  end

  s.subspec 'SecSDKPub' do |cs|
    cs.dependency 'SecSDK/ver-pub'
  end

  s.subspec 'SecSDKKA' do |cs|
    cs.dependency 'SecSDK/ver-ka-hz'
  end

  # 授权登录 / LarkSSO SDK
  s.subspec 'Authorization' do |cs|
    cs.source_files = 'src/Authorization/**/*.{swift,h,m,mm,cpp}'

    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkAccount_Authorization' }
    cs.dependency 'LarkAccount/Core'
    cs.dependency 'ECOProbeMeta'
  end

  # Key Account Feature Impl
  s.subspec 'KA' do |cs|
    cs.source_files = 'src/SuiteLogin/KeyAccount/Impl/**/*.{swift,h,m,mm,cpp}'
    cs.dependency 'LarkAccount/Core'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D SUITELOGIN_KA' }
    cs.dependency 'AnyCodable-FlightSchool', '~> 0.2.3'
    cs.dependency 'LKLifecycleExternalAssembly'
    cs.dependency 'LKPassportExternalAssembly'
  end

  s.subspec 'UI' do |cs|
    cs.source_files = "src/UI/**/*.{swift,h,m,mm,cpp}"
    cs.dependency 'LarkAccount/Configurations'
    cs.dependency 'LarkUIKit'
    cs.dependency 'SnapKit'
    cs.dependency 'EENavigator'
  end

  s.subspec 'AppsFlyerFramework' do |cs|
    cs.source_files = 'src/AppsFlyerFramework/**/*.{h,m,mm,swift}'
    cs.dependency 'LarkAccount/Core'
    cs.dependency 'AppsFlyerFramework'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkAccount_APPSFLYERFRAMEWORK' }
  end

  # 其他扩展功能
  s.subspec 'NativePlugin' do |cs|
    cs.source_files = "src/NativePlugin/**/*.{swift,h,m,mm,cpp}"

    cs.dependency 'ECOProbeMeta'
  end

  # Rust扩展实现
  s.subspec 'RustPlugin' do |cs|
    cs.source_files = "src/RustPlugin/**/*.{swift,h,m,mm,cpp}"

    cs.dependency 'LKCommonsLogging'
    cs.dependency 'LarkAppLinkSDK'
    cs.dependency 'LarkFeatureGating'
    cs.dependency 'LarkFeatureSwitch'
    cs.dependency 'LarkShareToken'
    cs.dependency 'LarkAppConfig'
    cs.dependency 'LarkRustClient'
    cs.dependency 'LarkAccount/Core'
    cs.dependency 'LarkRustHTTP'
    cs.dependency 'SuiteAppConfig'
    cs.dependency 'ECOProbeMeta'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkAccount_RUST' }
  end

  s.subspec 'NativeCaptcha' do |cs|
    cs.dependency 'CaptchaTokenCrypto'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkAccount_NativeCaptcha' }
  end

  s.subspec 'BootManager' do |cs|
    cs.source_files = "src/BootManager/**/*.{swift,h,m,mm,cpp}"
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkAccount_BootManager'}

    cs.dependency 'ECOProbeMeta'
  end

  # i18n & res
  s.subspec 'Configurations' do |cs|
      cs.source_files = 'src/configurations/**/*.{swift,h,m,mm,cpp}'
      cs.dependency 'LarkLocalizations'
      cs.resource_bundles = {
            'LarkAccount' => ['resources/*'] ,
            'LarkAccountAuto' => ['auto_resources/*']
      }
   end
end
