# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkExtensionServices.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkExtensionServices'
  s.version = '5.31.0.5479662'
  s.summary          = 'Extension基建'
  s.description      = 'Extension基建'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "王元洵": 'wangyuanxun@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.resource_bundles = {
  #     'LarkExtensionServices' => ['resources/*.lproj/*', 'resources/*'],
  #     'LarkExtensionServicesAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  # }

  # 配置模块
  s.subspec 'Config' do |sub|
    sub.source_files = 'src/Config/**/*.swift'
  end

  # 日志模块
  s.subspec 'Log' do |sub|
    sub.source_files = 'src/Log/**/*.{swift,h,m}'
    sub.dependency 'RustSimpleLogSDK'
    sub.dependency 'LarkStorageCore'
  end

  # 埋点模块
  s.subspec 'Track' do |sub|
    sub.source_files = 'src/Track/**/*.{swift,h,m}'
  end

  # 账户模块
  s.subspec 'Account' do |sub|
    sub.source_files = 'src/Account/**/*.swift'

    sub.dependency 'LarkExtensionServices/Config'
    sub.dependency 'CryptoSwift'
  end

  # 网络模块
  s.subspec 'Network' do |sub|
    sub.source_files = 'src/Network/**/*.swift'

    sub.dependency 'LarkExtensionServices/Config'
    sub.dependency 'LarkExtensionServices/Account'
    sub.dependency 'LarkExtensionServices/Log'
    sub.dependency 'LarkExtensionServices/Track'
    sub.dependency 'LarkHTTP'
  end

  # 域名模块
  s.subspec 'Domain' do |sub|
    sub.source_files = 'src/Domain/**/*.{swift,h,m}'
    sub.dependency 'LarkExtensionServices/Config'
  end

  # KV模块
  s.subspec 'KeyValue' do |sub|
    sub.source_files = 'src/KeyValue/**/*.swift'

    sub.dependency 'MMKVAppExtension'
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
  s.xcconfig = {
  'SWIFT_OPTIMIZATION_LEVEL' => '-Osize',
  'GCC_OPTIMIZATION_LEVEL'  => 'z',
  'DEAD_CODE_STRIPPING' => 'YES',
  'DEPLOYMENT_POSTPROCESSING' => 'YES',
  'STRIP_INSTALLED_PRODUCT' => 'YES',
  'STRIP_STYLE' => 'all',
  'STRIPFLAGS' => '-u',
  'GCC_SYMBOLS_PRIVATE_EXTERN' => 'YES'
  }
end
