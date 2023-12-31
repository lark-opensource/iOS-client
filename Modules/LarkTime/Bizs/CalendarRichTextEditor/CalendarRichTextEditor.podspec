Pod::Spec.new do |s|
  s.name             = 'CalendarRichTextEditor'
  s.version = "3.42.0-alpha.1"
  s.license          = 'MIT'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-pb/tree/master/'
  s.summary          = 'A short description of CalendarDocs.'

  s.author           = { 'zhangwei.wy' => 'zhangwei.wy@bytedance.com' }
  s.source           = { :git => 'ssh://git.byted.org:29418/ee/lark/ios-calendar', :tag => s.version.to_s }
  s.platform      = :ios
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.dependency 'SnapKit'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'SwiftyJSON'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkEMM'
  s.dependency 'LKCommonsLogging'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'LarkFeatureGating'
  s.dependency 'EENavigator'
  s.dependency 'LarkTraitCollection'
  s.dependency 'LarkSplitViewController'
  s.dependency 'LarkEditorJS'
  s.dependency 'LarkExtensions'
  s.dependency 'LKCommonsTracker'
  s.dependency 'LarkRustHTTP'
  s.dependency 'LarkWebViewContainer'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'CalendarFoundation'
  s.dependency 'UniverseDesignFont'
  
  s.source_files  = 'src/**/*.swift'
  s.resource_bundles = {
      'CalendarRichTextEditor' => ['Resources/*'] ,
      'CalendarRichTextEditorAuto' => ['auto_resources/*']
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

end
