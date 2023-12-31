# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkAssetsBrowser.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#



  s.name             = 'LarkAssetsBrowser'
  s.version = '5.32.0.5484520'
  s.summary          = 'Lark 图片预览组件'
  s.description      = 'Lark 图片预览组件'
  s.homepage         = 'Lark 图片预览组件'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'email'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift,h,m}', 'src/AssetsBrowser/*.{swift,h,m}'
  s.resource_bundles = {
      'LarkAssetsBrowser' => ['resources/*.lproj/*', 'resources/*'],
      'LarkAssetsBrowserAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  s.subspec 'Base' do |sub|
    sub.source_files = ['src/Base/*.swift']
    sub.dependency 'UniverseDesignColor'
    sub.dependency 'UniverseDesignTheme'
  end

  s.subspec 'Biz' do |sub|
    sub.source_files = ['src/Base/*.{swift,h,m}', 'src/Biz/*.{swift,h,m}', 'src/configurations/*.{swift,h,m}']
    sub.dependency 'LarkAssetsBrowser/Base'
    sub.dependency 'LarkLocalizations'
    sub.dependency 'EENavigator'
    sub.dependency 'FigmaKit'
    sub.dependency 'SnapKit'
    sub.dependency 'Kingfisher'
    sub.dependency 'LarkExtensions'
    sub.dependency 'LarkFoundation'
    sub.dependency 'RoundedHUD'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'LarkButton'
    sub.dependency 'RxSwift'
    sub.dependency 'RxCocoa'
    sub.dependency 'LarkCamera'
    sub.dependency 'LarkKAFeatureSwitch'
    sub.dependency 'LarkUIKit'
    sub.dependency 'LarkImageEditor/V1'
    sub.dependency 'LarkActionSheet'
    sub.dependency 'LarkMedia'
    sub.dependency 'LarkSetting'
    sub.dependency 'LarkContainer'
    sub.dependency 'AppReciableSDK'
    sub.dependency 'ByteWebImage'
    sub.dependency 'UniverseDesignCheckBox'
    sub.dependency 'UniverseDesignDialog'
    sub.dependency 'UniverseDesignToast'
    sub.dependency 'LarkStorage/KeyValue'
    sub.dependency 'LarkStorage/Sandbox'
    sub.dependency 'UniverseDesignIcon'
    sub.dependency 'LarkVideoDirector'
    sub.dependency 'LarkFeatureGating'
    sub.dependency 'LarkMonitor'
    sub.dependency 'LarkCache'
  end

  s.default_subspecs = ['Biz']

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
end
