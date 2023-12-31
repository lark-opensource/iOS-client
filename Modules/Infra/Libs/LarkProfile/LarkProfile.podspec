# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkProfile.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkProfile'
  s.version = '5.31.0.5476399'
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
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkProfile' => ['resources/*.lproj/*', 'resources/*'],
      'LarkProfileAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  s.dependency 'LKCommonsLogging'

  s.subspec 'UI' do |sub|
    sub.source_files = ['src/UI/*.{swift,h,m}', 'src/configurations/*.{swift,h,m}']
    sub.dependency 'SnapKit'
    sub.dependency 'UniverseDesignTheme'
    sub.dependency 'UniverseDesignTabs'
    sub.dependency 'UniverseDesignTag'
    sub.dependency 'UniverseDesignColor'
    sub.dependency 'UniverseDesignEmpty'
    sub.dependency 'UniverseDesignDialog'
    sub.dependency 'UniverseDesignIcon'
    sub.dependency 'UniverseDesignInput'
    sub.dependency 'UniverseDesignToast'
    sub.dependency 'UniverseDesignFont'
    sub.dependency 'UniverseDesignButton'
    sub.dependency 'UniverseDesignAvatar'
    sub.dependency 'UniverseDesignActionPanel'
    sub.dependency 'UniverseDesignLoading'
    sub.dependency 'LarkLocalizations'
    sub.dependency 'EENavigator'
    sub.dependency 'RxSwift'
    sub.dependency 'RxCocoa'
    sub.dependency 'RichLabel'
    sub.dependency 'LarkTag'
    sub.dependency 'LarkUIKit'
    sub.dependency 'AppReciableSDK'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'FigmaKit'
    sub.dependency 'LarkBizAvatar'
    sub.dependency 'ThreadSafeDataStructure'
    sub.dependency 'FigmaKit'
  end

  s.subspec 'Biz' do |sub|
    sub.source_files = ['src/Biz/*.{swift,h,m}']
    sub.dependency 'LarkProfile/UI'
    sub.dependency 'RustPB'
    sub.dependency 'ByteWebImage/Lark'
    sub.dependency 'ByteWebImage/Core'
    sub.dependency 'LarkRustClient'
    sub.dependency 'LarkMessengerInterface'
    sub.dependency 'SuiteAppConfig'
    sub.dependency 'LKCommonsTracker'
    sub.dependency 'Homeric'
    sub.dependency 'ThreadSafeDataStructure'
    sub.dependency 'LarkFocusInterface'
    sub.dependency 'LarkFocus'
    sub.dependency 'LarkAssetsBrowser'
    sub.dependency 'LarkAvatar'
    sub.dependency 'LarkImageEditor'
    sub.dependency 'LarkFeatureGating'
    sub.dependency 'LarkSensitivityControl/API/Pasteboard'
    sub.dependency 'LarkSensitivityControl/API/Contacts'
    sub.dependency 'LarkContactComponent'
    sub.dependency 'LarkOpenSetting'
    sub.dependency 'LarkSetting'
  end

  s.subspec 'View' do |sub|
    sub.source_files = [
      'src/configurations/*.swift',
      'src/**/AddContactView.swift',
      'src/**/ProfileRelationship.swift'
    ]
    sub.resource_bundles = {
        'LarkProfile' => ['resources/*.lproj/*', 'resources/*'],
        'LarkProfileAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
    }
    sub.dependency 'LarkLocalizations'
    sub.dependency 'UniverseDesignButton'
  end
  
  s.default_subspecs = ['Biz']

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
