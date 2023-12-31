# coding: utf-8
#
# Be sure to run `pod lib lint LarkReactionView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|

  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = "LarkReactionView"
  s.version = '5.30.0.5410491'
  s.summary          = "Lark Reaction View"
  s.description      = "Required. 描述该Pod的功能组成等信息"
  s.homepage = 'ssh://lichen.arthur@git.byted.org:29418/ee/ios-infra'

  s.authors           = {
    "lichen": "lichen.arthur@bytedance.com"
  }

  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkReactionView' => ['resources/*'] ,
      'LarkReactionViewAuto' => 'auto_resources/*'
  }

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { :git => 'generated_by_eesc.zip', :tag => s.version.to_s}

  s.dependency 'LarkLocalizations'
  s.dependency 'UniverseDesignColor'
  s.dependency 'SnapKit'
  s.dependency 'LarkExtensions'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'LarkEmotion'

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  #attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  #}
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": "ssh://git.byted.org:29418/ee/ios-infra"
  }
end
