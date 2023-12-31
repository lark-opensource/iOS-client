# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkBytedCert.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkBytedCert'
  s.version = '5.31.0.5454457'
  s.summary          = '通用的人脸识别服务'
  s.description      = '依赖byted_cert, RustService、AccountService'
  s.homepage         = 'git.byted.org:29418/ee/ios-infra/Bizs/LarkBytedCert'
  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "tangyunfei": 'tangyunfei.tyf@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
    'LarkBytedCert' => ['resources/*']
}

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'RustPB'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'TTNetworkManager'
  s.dependency 'LarkFoundation'
  s.dependency 'byted_cert/bridgecore'
  s.dependency 'byted_cert/offline'
  s.dependency 'byted_cert/download'
  s.dependency 'RxSwift'
  s.dependency 'LarkRustClient'
  s.dependency 'Swinject'
  s.dependency 'LarkEnv'
  s.dependency 'LarkAccountInterface'
  s.dependency 'OfflineResourceManager'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkContainer'
  s.dependency 'LarkExtensions'

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
