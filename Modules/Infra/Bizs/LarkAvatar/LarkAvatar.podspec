# coding: utf-8
# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkAvatar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkAvatar'
  s.version = '5.31.0.5463166'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "Stormspirit": 'qihongye@bytedance.com'
  }

  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.resource_bundles = {
      'LarkAvatar' => ['resources/*'] ,
      'LarkAvatarAuto' => 'auto_resources/*'
  }

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

  s.subspec 'Core' do |cs|
    cs.source_files = 'src/**/*.{swift}'

    cs.dependency 'LarkLocalizations'
    cs.dependency 'UniverseDesignColor'
    cs.dependency 'LarkUIKit'
    cs.dependency 'EENavigator'
    cs.dependency 'RxSwift'
    cs.dependency 'ByteWebImage'
    cs.dependency 'UniverseDesignActionPanel'
    cs.dependency 'LarkBizAvatar'
  end
  
  s.if_pod 'LarkAssetsBrowser' do |cs|
    cs.dependency 'LarkAssetsBrowser'
    cs.dependency 'LarkVideoDirector/CameraKit'
    cs.dependency 'UniverseDesignDialog'
    cs.dependency 'LarkImageEditor'
    cs.source_files = 'LarkAssetsBrowser/**/*.{swift}'
  end
  
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
