Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'SecurityComplianceDebug'
  s.version = '5.31.0.5474466'
  s.summary          = '安全合规高级调试组件，不上线'
  s.description      = '安全合规高级调试组件，不上线'
  s.homepage         = 'https://code.byted.org/lark/ios_security_and_compliance'

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'chengqingchun@bytedance.com'
  }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'

  s.source_files = 'src/**/*.{swift,h,m}'
  s.resource_bundles = {
      'SecurityComplianceDebug' => ['resources/*.lproj/*', 'resources/*'],
      'SecurityComplianceDebugAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
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
  
  s.dependency 'LarkAssembler'
  s.dependency 'EENavigator'
  s.dependency 'LarkSecurityCompliance/Debug'
  s.dependency 'LarkSecurityComplianceInfra'
  s.dependency 'LarkSceneManager'
  s.dependency 'LarkAccountInterface'
  s.dependency 'SnapKit'
  s.dependency 'SwiftyJSON'
  s.dependency 'UniverseDesignMenu'
  s.dependency 'BDRuleEngine/Debug'
  s.dependency 'LarkSensitivityControl'
  s.dependency 'LarkSensitivityControl/InHouse'
  s.dependency 'LarkPrivacyMonitor/InHouse'
  s.dependency 'RustPB'
  s.dependency 'LKLoadable'
end
