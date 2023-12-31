Pod::Spec.new do |s|
  s.name             = 'SCDemoImp'
  s.version = '5.27.0.5310223'
  s.summary          = '安全合规Example工程内部组件，不对外开放'
  s.description      = '安全合规Example工程内部组件，不对外开放'
  s.homepage         = 'https://code.byted.org/lark/ios_security_and_compliance'

  s.authors = {
    "name": 'chengqingchun@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'SCDemoImp' => ['resources/*.lproj/*', 'resources/*'],
      'SCDemoImpAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'git@code.byted.org:lark/ios_security_and_compliance.git'
  }

  s.dependency 'Swinject'
  s.dependency 'LarkContainer'
  s.dependency 'LarkTab'
  s.dependency 'LarkUIKit'
  s.dependency 'EENavigator'
  s.dependency 'LarkDebug'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkSecurityComplianceInfra'
  s.dependency 'LarkSecurityCompliance'
  s.dependency 'RxCocoa'
  s.dependency 'RxSwift'
  s.dependency 'AnimatedTabBar'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkAccountInterface'
  s.dependency 'SecurityComplianceDebug'

end
