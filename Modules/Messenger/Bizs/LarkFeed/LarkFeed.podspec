# frozen_string_literal: true
# coding: utf-8


#
# Be sure to run `pod lib lint LarkFeed.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范*  podspec规范
  s.name             = 'LarkFeed'
  s.version = '5.32.0.5486858'
  s.summary          = '重构的LarkFeed模块'
  s.description      = '主要围绕可拓展性，将业务部分从原Pod中分离，便于未来扩展其他内容'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkFeed'

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "夏汝震": 'xiaruzhen@bytedance.com',
    "袁平": 'yuanping.0@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift,h,m,c}'
  s.resource_bundles = {
      'LarkFeed' => ['resources/*.lproj/*', 'resources/*'] ,
      'LarkFeedAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }
  s.preserve_paths = 'configurations/**/*'


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'AppReciableSDK'
  s.dependency 'LarkStorage/KeyValue'
  s.dependency 'EENavigator'
  s.dependency 'EETroubleKiller'
  s.dependency 'FigmaKit'
  s.dependency 'Homeric'
  s.dependency 'LarkAppResources'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkBadge'
  s.dependency 'LarkBGTaskScheduler'
  s.dependency 'LarkBizAvatar'
  s.dependency 'LarkContainer'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkFeatureSwitch'
  s.dependency 'LarkOpenFeed'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkInteraction'
  s.dependency 'LarkKeyCommandKit'
  s.dependency 'LarkKAFeatureSwitch'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkPerf'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkSwipeCellKit'
  s.dependency 'LarkUIExtension'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkModel'
  s.dependency 'LarkFeedBanner'
  s.dependency 'LKLoadable'
  s.dependency 'LarkMonitor'
  s.dependency 'LarkFocus'
  s.dependency 'LarkEmotion'
  s.dependency 'LarkRichTextCore'
  s.dependency 'LarkTraitCollection'
  s.dependency 'LarkSplitViewController'
  s.dependency 'RxCocoa'
  s.dependency 'RxDataSources'
  s.dependency 'RxSwift'
  s.dependency 'SnapKit'
  s.dependency 'SuiteAppConfig'
  s.dependency 'Swinject'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignFont'
  s.dependency 'UniverseDesignTabs'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'UniverseDesignNotice'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignActionPanel'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'LarkEMM'
  s.dependency 'LarkBizTag'
  s.dependency 'LarkDocsIcon'
  # 剪贴板
  s.dependency 'LarkSensitivityControl/API/Pasteboard'
  s.dependency 'LarkFeedBase'

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程： Lark机器人配置小教程
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'https://ee.byted.org/madeira/repo/lark/LarkMessenger/'
  }

  s.test_spec 'Tests' do |test_spec|
    test_spec.test_type = :unit
    # 指定单测时参与编译的代码文件
    test_spec.source_files = 'tests/**/*.{swift,h,m}'
    test_spec.pod_target_xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
    }
    test_spec.scheme = {
      :code_coverage => true
    }
  end

end
