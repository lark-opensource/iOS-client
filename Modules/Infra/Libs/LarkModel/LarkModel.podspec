Pod::Spec.new do |s|
  s.name          = 'LarkModel'
  s.version = '5.31.0.5424672'
  s.author        = { 'Liu Wanlin' => 'liuwanlin@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkModel'
  s.summary       = '从pb的Model转各自模块的Model'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkModel', :tag => s.version.to_s }
  s.platform      = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  
  s.subspec 'Main' do |ss|
    ss.source_files  = 'Model/**/*.{swift}', 'Protos/Lark/Entities.pb.swift'
    ss.dependency 'RustPB'
    ss.dependency 'LKCommonsLogging'
    ss.dependency 'ServerPB'
    ss.dependency 'LarkLocalizations'
  end
  
  s.subspec 'Base' do |ss|
    ss.source_files = 'Model/{PickerConfig}/**/*.swift'
    ss.dependency 'RustPB'
    ss.dependency 'RxSwift'
  end

end
