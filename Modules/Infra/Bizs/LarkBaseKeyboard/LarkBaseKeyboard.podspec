# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkBaseKeyboard.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkBaseKeyboard'
  s.version          = '0.0.1-alpha.0'
  s.summary          = '键盘业务功能组件'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "liluobin": 'liluobin@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }
  s.dependency 'LarkLocalizations'

  attributes_hash = s.instance_variable_get('@attributes_hash')

  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'Required.'
  }

  # InputHanders
  s.subspec 'InputHanders' do |sub|
    sub.source_files = 'src/InputHanders/*.{swift,h,m}'
    sub.dependency 'LarkUIKit'
    sub.dependency 'LarkRichTextCore'
    sub.dependency 'EditTextView'
    sub.dependency 'LarkEMM'
    sub.dependency 'RustPB'
    sub.dependency 'LarkStorage'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'TangramService'
    sub.dependency 'LarkFeatureGating'
    sub.dependency 'LarkAppLinkSDK'
    sub.dependency 'RxSwift'
    sub.dependency 'LarkBaseKeyboard/Transformers'
    sub.dependency 'LarkBaseKeyboard/Tool'
  end

  # Transformers
  s.subspec 'Transformers' do |sub|
    sub.source_files = 'src/Transformers/**/*.{swift,h,m}'
    sub.dependency 'LarkModel'
    sub.dependency 'LarkUIKit'
    sub.dependency 'EditTextView'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'LarkEmotion'
    sub.dependency 'UniverseDesignTheme'
    sub.dependency 'LarkFoundation'
    sub.dependency 'LarkExtensions'
    sub.dependency 'RustPB'
    sub.dependency 'LarkModel'
    sub.dependency 'LarkCompatible'
    sub.dependency 'RxSwift'
    sub.dependency 'ByteWebImage'
    sub.dependency 'EditTextView'
    sub.dependency 'UniverseDesignColor'
    sub.dependency 'LKRichView/Core'
    sub.dependency 'LKRichView/Code'
    sub.dependency 'UniverseDesignFont'
    sub.dependency 'LarkEmotion'
    sub.dependency 'ThreadSafeDataStructure'
    sub.dependency 'TangramService'
    sub.dependency 'LarkRichTextCore'
    sub.dependency 'LarkSetting'
    sub.dependency 'LarkBaseKeyboard/Resources'
  end

  # Tool
  s.subspec 'Tool' do |sub|
    sub.source_files = 'src/Tool/*.{swift,h,m}'
    sub.dependency 'EditTextView'
    sub.dependency 'RustPB'
    sub.dependency 'LarkUIKit'
    sub.dependency 'LarkExtensions'
    sub.dependency 'LarkFeatureGating'
    sub.dependency 'LarkBaseKeyboard/Transformers'
    sub.dependency 'LarkBaseKeyboard/Resources'
  end

  s.subspec 'Keyboard' do |sub|
    sub.source_files = 'src/Keyboard/*.{swift,h,m}'
    sub.dependency 'LarkKeyboardView'
    sub.dependency 'LarkOpenKeyboard'
    sub.dependency 'LarkCanvas'
    sub.dependency 'LarkBaseKeyboard/Transformers'
    sub.dependency 'LarkBaseKeyboard/Resources'
    sub.dependency 'LarkBaseKeyboard/Tool'
    sub.dependency 'LarkOpenIM'
  end

  s.subspec 'AtPanel' do |sub|
    sub.source_files = 'src/AtPanel/*.{swift,h,m}'
    sub.dependency 'LarkBaseKeyboard/Keyboard'
    sub.dependency 'TangramService'
    sub.dependency 'LarkUIKit'
  end

  s.subspec 'EmojiPanel' do |sub|
    sub.source_files = 'src/EmojiPanel/*.{swift,h,m}'
    sub.dependency 'LarkBaseKeyboard/Keyboard'
    sub.dependency 'LarkEmotion'
    sub.dependency 'LarkEmotionKeyboard'
    sub.dependency 'EENavigator'
    sub.dependency 'LarkUIKit'
    sub.dependency 'ByteWebImage'
    sub.dependency 'AppReciableSDK'
  end

  s.subspec 'FontPanel' do |sub|
    sub.source_files = 'src/FontPanel/*.{swift,h,m}'
    sub.dependency 'LarkBaseKeyboard/Keyboard'
    sub.dependency 'LarkRichTextCore'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'LarkOpenIM'
  end

  s.subspec 'PicturePanel' do |sub|
    sub.source_files = 'src/PicturePanel/*.{swift,h,m}'
    sub.dependency 'LarkBaseKeyboard/ImageAttachment'
    sub.dependency 'LarkAssetsBrowser'
    sub.dependency 'LKCommonsTracker'
    sub.dependency 'LarkUIKit'
    sub.dependency 'ByteWebImage'
    sub.dependency 'LarkStorage'
    sub.dependency 'AppReciableSDK'
  end

  s.subspec 'CanvasPanel' do |sub|
    sub.source_files = 'src/CanvasPanel/*.{swift,h,m}'
    sub.dependency 'LarkBaseKeyboard/ImageAttachment'
    sub.dependency 'LarkCanvas'
    sub.dependency 'EENavigator'
    sub.dependency 'LarkUIKit'
    sub.dependency 'ByteWebImage'
  end

  s.subspec 'ImageAttachment' do |sub|
    sub.source_files = 'src/ImageAttachment/*.{swift,h,m}'
    sub.dependency 'LarkBaseKeyboard/Keyboard'
    sub.dependency 'LarkAttachmentUploader'
  end

  s.subspec 'VociePanel' do |sub|
    sub.source_files = 'src/VociePanel/*.{swift,h,m}'
    sub.dependency 'LarkBaseKeyboard/Keyboard'
  end

  s.subspec 'MorePanel' do |sub|
    sub.source_files = 'src/MorePanel/*.{swift,h,m}'
    sub.dependency 'LarkBaseKeyboard/Keyboard'
    sub.dependency 'LarkModel'
  end

  s.subspec 'OtherPanel' do |sub|
    sub.source_files = 'src/OtherPanel/*.{swift,h,m}'
    sub.dependency 'LarkBaseKeyboard/Keyboard'
    sub.dependency 'LarkUIKit'
    sub.dependency 'LarkActionSheet'
    sub.dependency 'EENavigator'
    sub.dependency 'UniverseDesignToast'
    sub.dependency 'UniverseDesignIcon'
    sub.dependency 'UniverseDesignActionPanel'
  end

  s.subspec 'Resources' do |sub|
    sub.source_files = 'src/configurations/*.{swift,h,m}'
    sub.dependency 'LarkResource'
    sub.dependency 'UniverseDesignIcon'
    sub.dependency 'UniverseDesignColor'
    sub.dependency 'RustPB'
    sub.dependency 'LarkModel'
    sub.dependency 'LarkRichTextCore'
    sub.resource_bundles = {
      'LarkBaseKeyboard' => ['resources/*.lproj/*', 'resources/*'],
      'LarkBaseKeyboardAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
    }
  end

  s.default_subspecs = ['InputHanders', "Transformers", "Tool", "Keyboard", "Resources",
  "FontPanel", "AtPanel", "CanvasPanel", "EmojiPanel", "PicturePanel", "VociePanel", "MorePanel", "OtherPanel", "ImageAttachment"]
end
