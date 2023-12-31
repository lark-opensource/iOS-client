Pod::Spec.new do |s|
  s.name          = 'LarkFinance'
  s.version = '5.30.0.5434208'
  s.author        = { 'Su Peng' => 'supeng.charlie@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkFinance'
  s.summary       = '红包、钱包、支付'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkBusinessModule', :tag => s.version.to_s }
  s.resource_bundles = {
    'LarkFinance' => ['resources/*'],
    'LarkFinanceAuto' => ['auto_resources/*'],
  }
  s.preserve_paths = 'configurations/**/*'
  s.platform      = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.default_subspec = 'Core'

  s.subspec 'Core' do |sp|
    sp.source_files  = 'src/**/*.{swift,h,m}'
    sp.dependency 'SnapKit'
    sp.dependency 'RxSwift'
    sp.dependency 'EENavigator'
    sp.dependency 'LarkNavigator'
    sp.dependency 'LarkCore'
    sp.dependency 'LarkFoundation'
    sp.dependency 'LarkUIKit'
    sp.dependency 'LarkModel'
    sp.dependency 'LarkContainer'
    sp.dependency 'LarkAppConfig'
    sp.dependency 'LarkMessengerInterface'
    sp.dependency 'LarkAvatar'
    sp.dependency 'UniverseDesignActionPanel'
    sp.dependency 'UniverseDesignDatePicker'
    sp.dependency 'UniverseDesignFont'
    sp.dependency 'UniverseDesignTabs'
    sp.dependency 'UniverseDesignToast'
    sp.dependency 'UniverseDesignEmpty'
    sp.dependency 'UniverseDesignIcon'
    sp.dependency 'UniverseDesignColor'
    sp.dependency 'LarkSetting'
    sp.dependency 'LarkAssembler'
    sp.dependency 'AppReciableSDK'
    sp.dependency 'LarkPrivacySetting'
  end

  s.subspec 'Pay' do |sp|
#    sp.dependency 'CJPay/PayBiz'
    sp.dependency 'CJPay/UserCenter'
    sp.dependency 'CJPay/BDPay'
    sp.dependency 'CJPay/VerifyModules/VerifyModulesBase'
    sp.dependency 'CJPay/VerifyModules/Biopayment'
    sp.dependency 'CJPay/Extensions'
    sp.dependency 'CJPay/Resource'
    sp.dependency 'CJPay/PayWebView'
    sp.dependency 'CJPay/PayCore/Base'
    sp.dependency 'CJPayDebugTools'
    sp.dependency 'BDXServiceCenter'
    sp.dependency 'BDXLynxKit'
    sp.dependency 'BDXBridgeKit/Methods/Info'
    sp.dependency 'BDXBridgeKit/Methods/Route'
    sp.dependency 'BDXBridgeKit/Methods/Storage'
    sp.dependency 'BDXBridgeKit/Methods/Log'
    sp.dependency 'BDXBridgeKit/Methods/Event'
    sp.dependency 'BDXBridgeKit/Methods/UI'
    sp.dependency 'BDXBridgeKit/Methods/Media'
    sp.dependency 'BDXBridgeKit/Methods/Network'
    sp.dependency 'UniverseDesignActionPanel'
    sp.dependency 'UniverseDesignTheme'
    sp.dependency 'UniverseDesignToast'
    sp.dependency 'UniverseDesignDialog'
    sp.dependency 'IESWebViewMonitor/HybridMonitor'
    sp.dependency 'LarkBytedCert'
    sp.dependency 'Lynx'
    sp.dependency 'DouyinOpenPlatformSDK/Core'
    sp.dependency 'DouyinOpenPlatformSDK/Auth'
  end
end
