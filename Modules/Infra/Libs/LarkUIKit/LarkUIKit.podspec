# coding: utf-8

Pod::Spec.new do |s|
  s.name = 'LarkUIKit'
  s.version = '5.31.0.5461589'
  s.author = {'Li Yuguo' => 'liyuguo.jeffrey@bytedance.com'}
  s.license = 'MIT'
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/ios/LarkUIKit/tree/master/'
  s.summary = 'LarkUIKit'
  s.source = {:git => 'ssh://git.byted.org:29418/ee/ios/LarkUIKit', :tag => s.version.to_s}
  s.platform = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }

  s.subspec 'OtherDependency' do |cs|
    cs.source_files = ['src/**/*.swift']
    cs.dependency 'LarkExtensions'
    cs.dependency 'RichLabel'
    cs.dependency 'LarkActivityIndicatorView'
    cs.dependency 'LarkReleaseConfig'
    cs.dependency 'LarkLocalizations'
  end

  s.subspec 'Others' do |cs|
    cs.source_files = ['LarkUIKit/**/*.swift']
    cs.exclude_files = [
      'LarkUIKit/AssetPickerSuite/ImagePicker/**/*.swift',
      'LarkUIKit/AssetPickerSuite/PhotoScrollPicker/**/*.swift',
      'LarkUIKit/Resources/*',
      'LarkUIKit/Common/*',
      'LarkUIKit/Switch/*.swift',
      'LarkUIKit/WebView/**/*',
      'LarkUIKit/Base/*.swift',
      'LarkUIKit/LoadPlaceholderView/*.swift',
      'LarkUIKit/Utils/*.swift',
      'LarkUIKit/NaviBar/*.swift',
      'LarkUIKit/NaviProtocol/*.swift',
      'LarkUIKit/TextField/*.swift'
    ]
    cs.dependency 'LarkFoundation'
    cs.dependency 'SnapKit'
    cs.dependency 'Kingfisher'
    cs.dependency 'RxSwift'
    cs.dependency 'RxCocoa'
    cs.dependency 'LarkUIKit/Common'
    cs.dependency 'LarkBadge'
    cs.dependency 'LarkEmotion'
    cs.dependency 'LarkButton'
    cs.dependency 'LarkKeyCommandKit'
    cs.dependency 'LarkInteraction'
    cs.dependency 'LarkAlertController' # fix Byteview dependency
    cs.dependency 'LarkActionSheet' # fix Byteview dependency
    cs.dependency 'UniverseDesignCheckBox'
    cs.dependency 'UniverseDesignBreadcrumb'
    cs.dependency 'UniverseDesignLoading'
  end

  # 所有的资源文件包括： 图片、表情、I18n的Strings
  s.subspec 'Resources' do |cs|
    cs.source_files = 'src/configurations/**/*'
    cs.resource_bundles = {
      'LarkUIKit' => 'LarkUIKit/Resources/*',
      'LarkUIKitAuto' => ['auto_resources/*']
    }
    cs.dependency 'LarkResource'
  end

  s.subspec 'Menu' do |cs|
    cs.source_files = 'LarkUIKit/Menu/**/*.{h,m,swift}'
    cs.dependency 'LarkBadge'
    cs.dependency 'UniverseDesignColor'
    cs.dependency 'SnapKit'
    cs.dependency 'FigmaKit'
    cs.dependency 'LarkFeatureGating'
  end

  # I18n、Resources、CommonResources
  s.subspec 'Common' do |cs|
    cs.source_files = 'LarkUIKit/Common/*.swift'
    cs.dependency 'LarkFoundation'
    cs.dependency 'UniverseDesignEmpty'
    cs.dependency 'LarkUIKit/Resources'
  end

  # FloatWindow >> Base
  s.subspec 'FloatWindow' do |cs|
    cs.source_files = 'LarkUIKit/FloatWindow/*.swift'
  end

  # Checkbox
  s.subspec 'Checkbox' do |cs|
    cs.source_files = 'LarkUIKit/Checkbox/*.swift'
    cs.dependency 'UniverseDesignColor'
    cs.dependency 'UniverseDesignCheckBox'
    cs.dependency 'LarkLocalizations'
    cs.dependency 'LarkExtensions'
  end

  # ConfirmContainer
  s.subspec 'ConfirmContainer' do |cs|
    cs.source_files = 'LarkUIKit/ConfirmContainer/*.swift'
    cs.dependency 'SnapKit'
    cs.dependency 'UniverseDesignColor'
  end

  # Switch
  s.subspec 'Switch' do |cs|
    cs.source_files = 'LarkUIKit/Switch/*.swift'
    cs.dependency 'UniverseDesignColor'
    cs.dependency 'SnapKit'
  end

  s.subspec 'BaseComponent' do |cs|
    cs.dependency 'LarkUIKit/FloatWindow'
    cs.dependency 'LarkUIKit/Checkbox'
    cs.dependency 'LarkUIKit/ConfirmContainer'
    cs.dependency 'LarkUIKit/Switch'
  end

  s.subspec 'MobileCodeSelect' do |cs|
    cs.source_files = 'LarkUIKit/MobileCodeSelect/*.swift'
    cs.dependency 'LarkUIKit/Common'
    cs.dependency 'SnapKit'
    cs.dependency 'UniverseDesignColor'
    cs.dependency 'LarkReleaseConfig'
    cs.dependency 'LarkStorage/Sandbox'
  end

  s.subspec 'LanguageSelector' do |cs|
    cs.source_files = 'LarkUIKit/LanguageSelector/*.swift'
  end

  s.subspec 'Base' do |cs|
    cs.source_files = 'LarkUIKit/Base/*.swift'

    cs.dependency 'LarkUIKit/Utils'
    cs.dependency 'RoundedHUD'
    cs.dependency 'SnapKit'
    cs.dependency 'RxSwift'
    cs.dependency 'LKCommonsLogging'
    cs.dependency 'EditTextView'
    cs.dependency 'LarkInteraction'
    cs.dependency 'LarkTraitCollection'
    cs.dependency 'LarkExtensions' # .lu
    cs.dependency 'Kingfisher' # .kf
    cs.dependency 'LarkAlertController' # fix Byteview dependency
    cs.dependency 'LarkActionSheet' # fix Byteview dependency
    cs.dependency 'LarkSceneManager'
    cs.dependency 'UniverseDesignEmpty'
    cs.dependency 'UniverseDesignColor'
    cs.dependency 'UniverseDesignDialog'
    cs.dependency 'FigmaKit'
    cs.dependency 'UniverseDesignIcon'
    cs.dependency 'LarkSensitivityControl/Core'
    cs.dependency 'LarkStorage'
  end

  s.subspec 'LoadPlaceholder' do |cs|
    cs.source_files = 'LarkUIKit/LoadPlaceholderView/*.swift'

    cs.dependency 'lottie-ios', "~>2.0"
    cs.dependency 'UniverseDesignTheme'
    cs.dependency 'UniverseDesignLoading'
  end

  s.subspec 'Utils' do |cs|
    cs.source_files = 'LarkUIKit/Utils/*.*'

    cs.dependency 'LarkFoundation'
    cs.dependency 'LarkLocalizations'
    cs.dependency 'Kingfisher' # .kf
    cs.dependency 'ByteWebImage'
    cs.dependency 'LarkReleaseConfig'
    cs.dependency 'LarkSensitivityControl/Core'
    cs.dependency 'LarkStorage/KeyValue'
  end

  s.subspec 'NaviBar' do |cs|
    cs.source_files = 'LarkUIKit/NaviBar/**/*.swift'

    cs.dependency 'LarkUIKit/NaviProtocol'
    cs.dependency 'LarkUIKit/TextField'
    cs.dependency 'LarkBadge'
  end

  s.subspec 'NaviProtocol' do |cs|
    cs.source_files = 'LarkUIKit/Navigation/**/*.swift'

    cs.dependency 'RxSwift'
    cs.dependency 'RxCocoa'
    cs.dependency 'SnapKit'
  end
  
  s.subspec 'TextField' do |cs|
    cs.source_files = 'LarkUIKit/TextField/**/*.swift', 'LarkUIKit/Base/BaseTextField.swift', 'LarkUIKit/Utils/Display.swift'

    cs.dependency 'LarkInteraction'
  end
  
  s.subspec 'BaseImageView' do |cs|
    cs.source_files = 'LarkUIKit/BaseImageView/*.swift'
    
    cs.dependency 'SnapKit'
    cs.dependency 'LarkCompatible'
    cs.dependency 'ByteWebImage'
    cs.dependency 'LarkSetting'
    cs.dependency 'UniverseDesignIcon'
  end
    

  s.subspec 'NaviAimation' do |cs|
      cs.source_files = 'LarkUIKit/NaviAnimation/**/*.swift'
      cs.dependency 'LarkUIKit/Base'
  end

  s.subspec 'BreadcrumbNavigation' do |cs|
      cs.source_files = 'LarkUIKit/BreadcrumbNavigation/*.swift'

      cs.dependency 'UniverseDesignBreadcrumb'
  end
    
  s.subspec 'LoadMore' do |cs|
      cs.source_files = 'LarkUIKit/LoadMore/*.swift'
      cs.dependency 'SnapKit'
  end

  # CaptureShield
  s.subspec 'CaptureShield' do |cs|
    cs.source_files = 'LarkUIKit/CaptureShield/*.swift'
  end
end
