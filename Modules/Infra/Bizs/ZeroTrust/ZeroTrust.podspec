# frozen_string_literal: true

#
# Be sure to run `pod lib lint ZeroTrust.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'ZeroTrust'
  s.version = '5.30.0.5410491'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'email'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'LarkAssembler'
  # s.public_header_files = 'Pod/Classes/**/*.h'

  s.subspec 'Base' do |cs|
    cs.source_files = 'src/Base/**/*.swift'
    cs.dependency 'LarkStorage/KeyValue'
	cs.dependency 'LarkStorage/Lark'
  end

  s.subspec 'Common' do |cs|
    cs.source_files = 'src/Common/**/*.{swift}', 'src/configurations/**/*.{swift}'
    cs.resource_bundles = {
        'ZeroTrustAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
    }

    cs.dependency 'ZeroTrust/Base'
    cs.dependency 'LarkLocalizations'
    cs.dependency 'Swinject'
    cs.dependency 'EENavigator'
    cs.dependency 'RustPB'
    cs.dependency 'RxSwift'
    cs.dependency 'LarkFoundation'
    cs.dependency 'LKCommonsLogging'
    cs.dependency 'LarkExtensions'
    cs.dependency 'LarkRustClient'
    cs.dependency 'LarkContainer'
    cs.dependency 'RoundedHUD'
    cs.dependency 'LarkFeatureGating'
  end

  # https://guides.cocoapods.org/syntax/podspec.html#default_subspecs
  # On one side, a specification automatically inherits as a dependency all it children ‘sub-specifications’ (unless a default subspec is specified).
  # You may use the value :none to specify that none of the subspecs are required to compile this pod and that all subspecs are optional.
  s.default_subspecs = ['Common']

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
