# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkVote.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkVote'
  s.version = '5.30.0.5410491'
  s.summary          = '群投票模块'
  s.description      = '创建投票、投票卡片'
  s.homepage         = 'https://code.byted.org/lark/Lark-Messenger/tree/develop/Bizs/LarkVote'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'qujieye'
  }

  s.preserve_paths = 'configurations/**/*'

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.resource_bundles = {
      'LarkVote' => ['resources/*'] ,
      'LarkVoteAuto' => ['auto_resources/*'],
  }

  s.subspec 'Common' do |sub|
    sub.source_files = 'src/configurations/**/*.{swift,h,m}'
  end

  # Assembly
  s.subspec 'Assembly' do |sub|
  sub.source_files = 'src/Assembly/**/*.{swift,h,m}'
  sub.dependency 'Swinject'
  sub.dependency 'LarkAssembler'
  end

  # CreateVote
  s.subspec 'CreateVote' do |sub|
    sub.source_files = 'src/CreateVote/**/*.{swift,h,m}'
    sub.dependency 'RxSwift'
    sub.dependency 'RustPB'
    sub.dependency 'LarkMessengerInterface'
    sub.dependency 'LarkKeyboardKit'
  end

  # CreateVote
  s.subspec 'VoteContent' do |sub|
    sub.source_files = 'src/VoteContent/**/*.{swift,h,m}'
    sub.dependency 'RxSwift'
    sub.dependency 'RustPB'
  end

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'LarkLocalizations'
  s.dependency 'EENavigator'
  s.dependency 'SnapKit'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkCore'
  s.dependency 'RxSwift'
  s.dependency 'LarkFeatureGating'
  s.dependency 'UniverseDesignColor'
  s.dependency 'LarkAssembler'
  s.dependency 'UniverseDesignToast'
  s.dependency 'UniverseDesignFont'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'RustPB'
  s.dependency 'LarkRustClient'
  s.dependency 'Swinject'
  s.dependency 'LarkSDKInterface'
  s.dependency 'LarkContainer'
  s.dependency 'UniverseDesignProgressView'
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

  s.default_subspecs = ['CreateVote', 'Assembly', 'VoteContent', 'Common']
end
