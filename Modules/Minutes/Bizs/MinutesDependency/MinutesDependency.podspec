# frozen_string_literal: true

#
# Be sure to run `pod lib lint MinutesDependency.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'MinutesDependency'
  s.version          = '0.1.0'
  s.summary          = '妙记外部依赖仓库模块'
  s.description      = '妙记外部依赖仓库模块， 目前有依赖于会议， CCM， IM等功能的接口'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'panzaofeng@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/*.{swift}'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

    s.subspec 'Core' do |sp|
      sp.source_files = ['src/Core/*.{swift}', 'src/Config/*.{swift}']

      sp.dependency 'Swinject'
      sp.dependency 'LarkFeatureGating'
      sp.dependency 'EENavigator'
      sp.dependency 'LarkFoundation'
      sp.dependency 'LarkUIKit'
      sp.dependency 'Minutes'
      sp.dependency 'LarkAssembler'
      sp.dependency 'LarkAppLinkSDK'
      sp.dependency 'LarkSDKInterface'
      sp.dependency 'LarkKAFeatureSwitch'
      sp.dependency 'RustPB'
    end

    s.if_pod 'MessengerMod' do |cs|
      cs.source_files = ['src/Messenger/*.{swift}']
      cs.dependency 'LarkMessengerInterface'
      cs.dependency 'LarkForward'
    end

    s.if_pod 'LarkLiveMod' do |cs|
      cs.source_files = ['src/LarkLive/*.{swift}']
      cs.dependency 'LarkLiveInterface'
    end

    s.if_pod 'ByteViewMod' do |cs|
      cs.source_files = ['src/ByteView/*.{swift}']
      cs.dependency 'ByteViewInterface'
    end

    s.if_pod 'CCMMod' do |cs|
      cs.source_files = ['src/CCM/*.{swift}']
      cs.dependency 'SpaceInterface'
      cs.dependency 'LarkDocsIcon'
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
