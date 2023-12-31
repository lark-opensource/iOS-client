# frozen_string_literal: true

#
# Be sure to run `pod lib lint Moment.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'Moment'
  s.version = '5.31.0.5464556'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'email'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*'
  s.resource_bundles = {
      'Moment' => ['resources/*.lproj/*', 'resources/*'],
      'MomentAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'
  s.dependency 'EENavigator'
  s.dependency 'BootManager'
  s.dependency 'Swinject'
  s.dependency 'RxSwift'
  s.dependency 'LarkRustClient'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'EEAtomic'
  s.dependency 'RustPB'
  s.dependency 'LarkTab'
  s.dependency 'AnimatedTabBar'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkUIKit'
  s.dependency 'EditTextView'
  s.dependency 'UniverseDesignToast'
  s.dependency 'LarkCore'
  s.dependency 'LarkMessageBase'
  s.dependency 'LarkMessageCore'
  s.dependency 'AsyncComponent'
  s.dependency 'EEFlexiable'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkModel'
  s.dependency 'LarkAccountInterface'
  s.dependency 'RichLabel'
  s.dependency 'LarkKeyboardKit'
  s.dependency 'LarkContainer'
  s.dependency 'LarkMenuController'
  s.dependency 'LarkEmotion'
  s.dependency 'LarkExtensions'
  s.dependency 'RxCocoa'
  s.dependency 'LarkReactionDetailController'
  s.dependency 'SkeletonView'
  s.dependency 'LarkButton'
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'LarkTimeFormatUtils'
  s.dependency 'UniverseDesignTabs'
  s.dependency 'UniverseDesignBadge'
  s.dependency 'UniverseDesignButton'
  s.dependency 'EditTextView'
  s.dependency 'LarkEmotionKeyboard'
  s.dependency 'UniverseDesignDatePicker'
  s.dependency 'UniverseDesignLoading'
  s.dependency 'Homeric'
  s.dependency 'LKCommonsTracker'
  s.dependency 'SuiteCodable'
  s.dependency 'LarkSearchCore'
  s.dependency 'LarkListItem'
  s.dependency 'AppReciableSDK'
  s.dependency 'ByteWebImage'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'LarkSetting'
  s.dependency 'TangramService'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'LarkProfile'
  s.dependency 'FigmaKit'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkEMM'
  s.dependency 'LarkAI'
  s.dependency 'LarkOpenSetting'
  s.dependency 'LarkSendMessage'
  s.dependency 'LarkBaseKeyboard'

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
