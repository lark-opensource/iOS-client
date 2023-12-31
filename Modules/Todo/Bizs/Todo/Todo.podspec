# frozen_string_literal: true

# valid spec before submitting. 
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
# 

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'Todo'
  s.version = '5.31.0.5484435'
  s.summary          = 'Todo'
  s.homepage         = 'https://code.byted.org/lark/calendar-ios'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "zhangwei": 'zhangwei.wy@bytedance.com'
  }
  s.platform = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.3"

  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'Todo' => ['resources/*'] ,
      'TodoAuto' => 'auto_resources/*'
  }

  s.license          = 'MIT'
  s.source           = { git: 'git@code.byted.org:lark/calendar-ios.git', tag: s.version.to_s }

  s.dependency 'AppContainer'
  s.dependency 'CTFoundation'
  s.dependency 'EENavigator'
  s.dependency 'AsyncComponent'
  s.dependency 'EEFlexiable'
  s.dependency 'LarkTag'
  s.dependency 'JTAppleCalendar'
  s.dependency 'LarkBizAvatar'
  s.dependency 'LarkPushCard'
  s.dependency 'LarkFeatureSwitch'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkMessageBase'
  s.dependency 'LarkModel'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkOpenChat'
  s.dependency 'LarkSwipeCellKit'
  s.dependency 'LarkTimeFormatUtils'
  s.dependency 'LarkUIKit'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'RichLabel'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxDataSources'
  s.dependency 'SnapKit'
  s.dependency 'TodoInterface'
  s.dependency 'ESPullToRefresh'
  s.dependency 'LarkSceneManager'
  s.dependency 'lottie-ios'
  s.dependency 'LarkZoomable'
  s.dependency 'LarkRichTextCore'
  s.dependency 'LarkKeyboardView'
  s.dependency 'LarkSplitViewController'
  s.dependency 'LarkActionSheet'
  s.dependency 'LarkMenuController'
  s.dependency 'LarkAssetsBrowser'
  s.dependency 'LarkVideoDirector/CameraKit'
  s.dependency 'SkeletonView'
  s.dependency 'LarkReactionView'
  s.dependency 'LarkReactionDetailController'
  s.dependency 'UniverseDesignToast'
  s.dependency 'AppReciableSDK'
  s.dependency 'UniverseDesignDatePicker'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignTabs'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignBadge'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'UniverseDesignProgressView'
  s.dependency 'LarkSnsShare'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkEMM'
  s.dependency 'UniverseDesignInput'
  s.dependency 'LarkBizTag/Chatter'
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'LarkSensitivityControl/API/Pasteboard'
  s.dependency 'LarkBaseKeyboard'
  s.dependency 'LarkChatOpenKeyboard'
  s.dependency 'LarkDocsIcon'

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
