# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkWidget.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkWidget'
  s.version = '5.30.0.5410491'
  s.summary          = 'Smart Widget集合，包含日程、扫一扫、搜索、创建文档、创建日程的快接入口~'
  s.description      = 'Smart Widget集合，包含日程、扫一扫、搜索、创建文档、创建日程的快接入口~'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  s.authors = {
    "name": 'zhanghongyun.0729@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkWidget' => ['resources/*.lproj/*', 'resources/*'],
      'LarkWidgetAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'LarkLocalizations'
  s.dependency 'LarkTimeFormatUtils'
  s.dependency 'LarkHTTP'
  s.dependency 'LarkExtensionServices'

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
