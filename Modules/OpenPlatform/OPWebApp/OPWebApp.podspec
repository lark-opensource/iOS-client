Pod::Spec.new do |s|
  s.name             = 'OPWebApp'
  s.version = '5.31.0.5463996'
  s.summary          = 'Open platform foundation'
  s.description      = "Open platform foundation，本模块不允许依赖任何的业务模块"
  s.homepage         = 'https://code.byted.org/ee/OPWebApp'
  s.author           = { 'taofengping' => 'taofengping@bytedance.com' }
  s.source           = { :git => 'git@code.byted.org:ee/OPWebApp.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.swift_version = "5.4"
  s.module_name  = 'OPWebApp'
  
  s.source_files = 'Classes/**/*.{h,m,mm,swift}'
  s.dependency 'OPSDK'
  s.dependency 'LarkOPInterface'
  s.dependency 'TTMicroApp'
  s.dependency 'ECOProbe'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkSetting'
  s.dependency 'LarkFeatureGating'
end
