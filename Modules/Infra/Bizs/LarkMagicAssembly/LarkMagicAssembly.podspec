# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkMagicAssembly.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

# 引入if_pod语法扩展
eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkMagicAssembly'
  s.version          = '5.7.0'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  s.dependency 'LarkLocalizations'
  s.dependency 'BootManager'
  s.dependency 'LarkContainer'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkMagic'
  s.dependency 'LarkAssembler'

  s.if_pod 'ByteViewMod' do |sp|
    sp.dependency 'ByteViewInterface'
  end

  s.if_pod 'LarkGuide' do |sp|
    sp.dependency 'LarkGuide'
  end

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'aslan.hu@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  # s.resource_bundles = {
  #     'LarkMagicAssembly' => ['resources/*.lproj/*', 'resources/*'],
  #     'LarkMagicAssemblyAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  # }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'

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
