Pod::Spec.new do |s|
  s.name             = 'CalendarFoundation'
  s.version = "3.42.0-alpha.1"
  s.description      = '日历对Fondation的扩展方法'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-pb/tree/master/'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'zhuheng.henry@bytedance.com'
  }

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'CalendarFoundation' => ['resources/*'] ,
      'CalendarFoundationAuto' => 'auto_resources/*'
  }

  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }
  s.summary          = '日历的Foundation'
  s.dependency 'LarkCompatible'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkLocalizations'
  s.dependency 'LKCommonsLogging'
  s.dependency 'RustPB'
  s.dependency 'RxSwift'
  s.dependency 'LarkButton'
  s.dependency 'LarkTag'
  s.dependency 'SnapKit'
  s.dependency 'RxCocoa'
  s.dependency 'LarkExtensions'
  s.dependency 'AppReciableSDK'
  s.dependency 'LarkTimeFormatUtils'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'LarkUIKit'
  s.dependency 'UniverseDesignFont'
  attributes_hash = s.instance_variable_get('@attributes_hash')
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'Required.'
  }
end
