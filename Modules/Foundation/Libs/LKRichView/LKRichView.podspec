# coding: utf-8
# frozen_string_literal: true

#
# Be sure to run `pod lib lint LKRichView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LKRichView'
  s.version = '5.31.0.5463996'
  s.summary          = '参考Webkit实现的富文本控件'
  s.description      = '参考Webkit实现的强大富文本控件'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/EEFoundation/tree/master/Libs/LKRichView/'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "Stormspirit": 'qihongye@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.source_files = 'src/**/*.{swift,h,m}'
  # s.resource_bundles = {
  #     'LKRichView' => ['resources/*'] ,
  #     'LKRichViewAuto' => 'auto_resources/*'
  # }

  # 基础功能
  s.subspec 'Core' do |sub|
    sub.source_files = 'src/**/*.{swift,h,m}'
    # 这里需要排除Core以外的文件
    sub.exclude_files = 'src/Code/**/*.swift'
  end
  # 代码块
  s.subspec 'Code' do |sub|
    sub.source_files = 'src/Code/**/*.swift'
  end

  # 默认只引Core，其他subspec业务Pod按需引入
  s.default_subspec = ['Core']

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
   "bot": "b-3f415de3-d784-416c-9fbf-ff3989beb186"
  }
  attributes_hash['extra'] = {
    "git_url": "ssh://git.byted.org:29418/ee/EEFoundation"
  }
end
