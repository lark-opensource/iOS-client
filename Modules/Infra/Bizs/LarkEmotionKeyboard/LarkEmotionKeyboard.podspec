# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkEmotionKeyboard.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patchb

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkEmotionKeyboard'
  s.version = '5.31.0.5475597'
  s.summary          = 'Lark聊天界面emotion面板'
  s.description      = 'Lark聊天界面emotion面板'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'


  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "王元洵": 'wangyuanxun@bytedance.com'
  }

  s.preserve_paths = 'configurations/**/*'

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'

  s.resource_bundles = {
      'LarkEmotionKeyboard' => ['resources/*'] ,
      'LarkEmotionKeyboardAuto' => ['auto_resources/*'],
  }

  s.subspec 'Common' do |sub|
    sub.source_files = 'src/configurations/**/*.{swift,h,m}'
  end

  # 表情面板
  s.subspec 'Keyboard' do |sub|
    sub.source_files = 'src/Keyboard/**/*.{swift,h,m}'
    sub.dependency 'SnapKit'
  end

  # Emoji
  s.subspec 'Emoji' do |sub|
    sub.source_files = 'src/Emoji/**/*.{swift,h,m}'
    sub.dependency 'LarkEmotionKeyboard/Keyboard'
    sub.dependency 'LarkEmotionKeyboard/Common'
    sub.dependency 'LarkEmotion'
    sub.dependency 'UniverseDesignColor'
    sub.dependency 'LarkFeatureGating'
    sub.dependency 'LarkContainer'
  end

  # EmojiDependency
  s.subspec 'EmojiDependency' do |sub|
    sub.source_files = 'src/EmojiDependency/**/*.{swift,h,m}'
    sub.dependency 'LarkEmotionKeyboard/Emoji'
    sub.dependency 'RxSwift'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'ThreadSafeDataStructure'
    sub.dependency 'RustPB'
    sub.dependency 'LarkContainer'
    sub.dependency 'LarkRustClient'
    sub.dependency 'LarkAccountInterface'
    sub.dependency 'LarkEmotion'
    sub.dependency 'LarkFloatPicker'
    sub.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkEmotion_EmojiDependency' }
  end

  # Reaction Panel
  s.subspec 'Panel' do |sub|
  sub.source_files = 'src/Panel/**/*.{swift,h,m}'
  sub.dependency 'LarkEmotionKeyboard/Common'
  sub.dependency 'SnapKit'
  end

  # Assembly
  s.subspec 'Assembly' do |sub|
  sub.source_files = 'src/Assembly/**/*.{swift,h,m}'
  sub.dependency 'LarkEnv'
  sub.dependency 'BootManager'
  sub.dependency 'Swinject'
  sub.dependency 'LarkRustClient'
  sub.dependency 'LKCommonsLogging'
  end

  # Sticker
  s.subspec 'Sticker' do |sub|
  sub.source_files = 'src/Sticker/**/*.{swift,h,m}'
  sub.dependency 'RustPB'
  sub.dependency 'ByteWebImage'
  sub.dependency 'RxSwift'
  sub.dependency 'RxCocoa'
  sub.dependency 'SnapKit'
  sub.dependency 'LKCommonsLogging'
  # 新增依赖
  sub.dependency 'LarkUIKit'
  sub.dependency 'AppReciableSDK'
  sub.dependency 'LarkModel'
  sub.dependency 'SkeletonView'
  sub.dependency 'UniverseDesignShadow'
  end

  # Reaction Image Delegate
  s.subspec 'Reaction' do |sub|
    sub.source_files = 'src/Reaction/**/*.{swift,h,m}'
    sub.dependency 'LarkEmotion'
    sub.dependency 'ByteWebImage'
    sub.dependency 'LarkEmotionKeyboard/Panel'
    sub.dependency 'LarkContainer'
    sub.dependency 'Homeric'
    sub.dependency 'LKCommonsTracker'
    sub.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkEmotion_Reaction' }
  end

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'Required.'
  }

  s.default_subspecs = ['Keyboard', 'Emoji', 'EmojiDependency', 'Panel', 'Reaction', 'Assembly', "Sticker"]
end
