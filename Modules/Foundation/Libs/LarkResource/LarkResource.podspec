# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkResource.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkResource'
  s.version          = '0.0.8'
  s.summary          = 'Lark Resource 资源管理模块'
  s.description      = 'Lark Resource 资源管理模块'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "lichen": 'lichen.arthur@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'

  s.source_files = 'src/**/*.{swift,h,m}'

  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'LKCommonsLogging'
  s.dependency 'EEAtomic'

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
