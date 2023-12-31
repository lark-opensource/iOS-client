Pod::Spec.new do |s|
  s.name             = 'OPDynamicComponent'
  s.version = '5.31.0.5463996'
  s.summary          = 'Open platform foundation'
  s.description      = "Open platform foundation，动态组件业务形态"
  s.homepage         = 'https://code.byted.org/ee/OPDynamicComponent'
  s.author           = { 'taofengping' => 'taofengping@bytedance.com' }
  s.source           = { :git => 'git@code.byted.org:ee/OPDynamicComponent.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.swift_version = "5.4"
  s.module_name  = 'OPDynamicComponent'
  s.source_files = 'Classes/**/*.{h,m,mm,swift}'
  s.dependency 'TTMicroApp'
  s.dependency 'OPSDK'
  s.dependency 'LarkOPInterface'
  s.dependency 'ECOProbe'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkSetting'
end
