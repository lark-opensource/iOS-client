# frozen_string_literal: true

#
# Be sure to run `pod lib lint OPBlockInterface.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'OPBlockInterface'
  s.version          = '5.31.0.5483135'
  s.summary          = 'OPBlock的声明模块'
  s.description      = 'Interface for OPBlock'
  s.homepage         = 'https://code.byted.org/ee/microapp-iOS-sdk/OPBlockInterface'

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "陈子祎": 'chenziyi.99@bytedance.com',
    "王飞": 'wangfei.heart@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.4'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  # s.resource_bundles = {
  #     'OPBlockInterface' => ['resources/*.lproj/*', 'resources/*'],
  #     'OPBlockInterfaceAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  # }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.source_files = 'src/**/*.{h,m,mm,swift}'
  s.dependency 'OPSDK'

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
