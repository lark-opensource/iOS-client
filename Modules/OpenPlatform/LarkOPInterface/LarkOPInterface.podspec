Pod::Spec.new do |s|
  s.name             = 'LarkOPInterface'
  s.version = '5.31.0.5463996'
  s.summary          = 'Open platform foundation'
  s.description      = "Open platform foundation，本模块不允许依赖任何的业务模块"
  s.homepage         = 'https://code.byted.org/ee/LarkOPInterface'
  s.author           = { 'yinhao' => 'yinhao@bytedance.com' }
  s.source           = { :git => 'git@code.byted.org:ee/LarkOPInterface.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.swift_version = "5.4"
  s.source_files = 'Classes/**/*.{h,swift}'
  s.module_name  = 'LarkOPInterface'
  s.dependency 'LarkModel'
  s.dependency 'RxSwift'
  s.dependency 'SwiftyJSON'
  s.dependency 'LarkShareContainer'
  s.dependency 'EENavigator'
  s.dependency 'RxRelay'
  s.dependency 'ECOInfra'
  s.dependency 'LarkOpenAPIModel'
  
  
  # ---------------------- OPInterfaceSwiftHeader ----------------------- #
  #  仅用于 import <LarkOPInterface/LarkOPInterface-Swift.h> 用途
  # --------------------------------------------------------------------- #
  s.subspec 'OPInterfaceSwiftHeader' do |ss|
    ss.source_files = 'Classes/OPInterfaceSwiftHeader/LarkOPInterface.h'
    ss.dependency 'ECOProbe'
  end
  
  # ---------------------- OPWeb ----------------------- #
  s.subspec 'OPWeb' do |ss|
    ss.source_files = 'Classes/OPWeb/**/*.{swift}'
    ss.dependency 'EENavigator'
  end

  # ---------------------- OPContextLogger ----------------------- #
  s.subspec 'OPContextLogger' do |ss|
    ss.source_files = 'Classes/OPContextLogger/**/*.{swift,h,m}'
  end

  # ---------------------- OPApp ----------------------- #
  s.subspec 'OPApp' do |ss|
    ss.source_files = 'Classes/OPApp/**/*.{swift,h,m}'
    ss.dependency 'EENavigator'
  end

  # ---------------------- MyAI ----------------------- #
  s.subspec 'MyAI' do |ss|
    ss.source_files = 'Classes/MyAI/**/*.{swift}'
    ss.dependency 'LarkQuickLaunchInterface'
    ss.dependency 'LarkQuickLaunchBar'
    ss.dependency 'LarkTab'
  end
  
  # ---------------------- OPWebBusinessPlugin ----------------------- #
  s.subspec 'OPWebBusinessPlugin' do |ss|
    ss.source_files = 'Classes/OPWebBusinessPlugin/**/*.{swift}'
    ss.dependency 'LarkQuickLaunchInterface'
    ss.dependency 'LarkUIKit'
  end
end
