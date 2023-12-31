Pod::Spec.new do |s|
  s.name             = 'LarkWorkplaceModel'
  s.version = '5.31.0.5463996'
  s.summary          = 'Lark Workplace Net Model Definition and Handler'
  s.description      = 'Lark Workplace Net Model Definition and Handler. Net Model Codable.'
  s.homepage         = 'https://code.byted.org/ee/microapp-iOS-sdk/tree/develop/LarkWorkplaceModel'

  s.authors = {
    "shengxiaoying": 'shengxiaoying.keri@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files = 'src/**/*.{swift}'

  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'SwiftyJSON'
  s.dependency 'ECOProbe'

  attributes_hash = s.instance_variable_get('@attributes_hash')
  attributes_hash['extra'] = {
    "git_url": 'git@code.byted.org:ee/microapp-iOS-sdk.git'
  }
end
