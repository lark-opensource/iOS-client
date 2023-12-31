# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkSendMessage.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSendMessage'
  s.version = '5.32.0.5486875'
  s.summary          = 'Lark中发消息逻辑'
  s.description      = 'Lark中发消息逻辑，统一收敛；Pod层级目前位于Messenger/Libs，LarkSendMessage目前只依赖LarkSDKInterface'
  s.homepage         = 'https://code.byted.org/lark/Lark-Messenger'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "李勇": 'liyong.520@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # Messenger/Libs
  s.dependency 'LarkSDKInterface'
  # Infra
  s.dependency 'LarkModel'
  s.dependency 'LarkContainer'
  s.dependency 'LarkStorage'
  s.dependency 'LarkAudioKit'
  s.dependency 'LarkDowngrade'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkLocalizations'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'LarkTracing'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkCompatible'
  s.dependency 'LarkDebugExtensionPoint'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkPerf'
  s.dependency 'LarkCache'
  s.dependency 'LarkDebug'
  s.dependency 'LarkRichTextCore'
  s.dependency 'LarkVideoDirector'
  s.dependency 'LarkMonitor'
  s.dependency 'LarkAIInfra'
  # Foundation
  s.dependency 'LKCommonsLogging'
  s.dependency 'FlowChart'
  s.dependency 'EEAtomic'
  s.dependency 'LKCommonsTracker'
  s.dependency 'EENavigator'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkStorage'
  # Passport
  s.dependency 'LarkAccountInterface'
  # Universe
  s.dependency 'UniverseDesignToast'
  # rust-sdk
  s.dependency 'RustPB'
  s.dependency 'ServerPB'
  # ByteWebImage
  s.dependency 'ByteWebImage'
  # RxSwift
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  # homeric_datas
  s.dependency 'Homeric'
  # appreciable_sdk
  s.dependency 'AppReciableSDK'
  # ttvideoeditor
  s.dependency 'TTVideoEditor'
  # Reachability，不能明确写依赖Reachability，预期是用系统的
  # s.dependency 'Reachability'

  s.resource_bundles = {
      'LarkSendMessage' => ['resources/*'] ,
      'LarkSendMessageAuto' => 'auto_resources/*'
  }

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
    # 指定单测资源所在的文件夹
    test_spec.resource_bundles = {
      'LarkSendMessageUnitTest' => ['tests/resources/*']
    }
  end
end
