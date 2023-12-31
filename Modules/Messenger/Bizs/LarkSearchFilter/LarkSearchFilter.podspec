Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSearchFilter'
  s.version = '5.30.0.5403035'
  s.summary          = '搜索过滤器组件'
  s.description      = '搜索过滤器组件'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkSearchFilter'

  s.authors = {
    "CharlieSu": 'supeng.charlie@bytedance.com'
  }

  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkSearchFilter' => ['resources/*'] ,
      'LarkSearchFilterAuto' => 'auto_resources/*'
  }

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'LarkModel'
  s.dependency 'LarkCore'
  s.dependency 'SnapKit'
  s.dependency 'DateToolsSwift'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkLocalizations'
  s.dependency 'JTAppleCalendar'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'LarkFeatureGating'
end
