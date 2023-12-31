Pod::Spec.new do |s|
  s.name          = 'LarkWebViewContainer'
  s.author        = { 'houzhiyou' => 'houzhiyou@bytedance.com' }
  s.homepage      = 'https://code.byted.org/ee/lark-webview-ios'
  s.ios.deployment_target = '11.0'
  s.license       = { :type => 'MIT', :file => 'LICENSE' }
  s.source        = { :git => 'git@code.byted.org:ee/lark-webview-ios.git', :tag => s.version.to_s }
  s.summary       = '飞书WebView统一容器'
  s.swift_version = '5.4'
  s.version = '5.31.0.5463996'
  s.dependency 'ECOInfra/ECOFoundation'
  s.dependency 'ECOInfra/ECONetwork'
  s.dependency 'ECOProbe/OPLog'
  s.dependency 'ECOProbe/OPMonitor'
  s.dependency 'ECOProbe/OPTrace'
  s.dependency 'LarkContainer'
  s.dependency 'ECOInfra/OPError'
  s.dependency 'LarkOPInterface/OPInterfaceSwiftHeader'
  s.dependency 'LarkSetting'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKLoadable'
  s.dependency 'LarkPrivacySetting'
  s.subspec 'Base' do |ss|
    ss.source_files = 'Classes/Base/**/*.{h,m,swift}'
  end
  s.subspec 'Bridge' do |ss|
    ss.source_files = 'Classes/Bridge/**/*.{swift}'
    ss.dependency 'LarkWebViewContainer/Base'
  end
  s.subspec 'Quality' do |ss|
    ss.source_files = 'Classes/Quality/**/*.{swift}'
    ss.dependency 'LarkWebViewContainer/Base'
  end
  s.subspec 'Container' do |ss|
    ss.source_files = 'Classes/Container/**/*.{h,m,swift}'
    ss.dependency 'LarkWebViewContainer/Base'
    ss.dependency 'LarkWebViewContainer/Bridge'
    ss.dependency 'LarkWebViewContainer/Quality'
  end
  s.subspec 'AjaxFetchHook' do |ss|
    ss.source_files = 'Classes/AjaxFetchHook/**/*.{h,m,swift}'
  end
  s.subspec 'Monitor' do |ss|
    ss.source_files = 'Classes/Monitor/**/*.{h,m,swift}'
    ss.dependency 'LarkWebViewContainer/Base'
    ss.dependency 'IESWebViewMonitor/Core'
    ss.dependency 'IESWebViewMonitor/CustomInterface'
    ss.dependency 'IESWebViewMonitor/HybridMonitor'
    ss.dependency 'IESWebViewMonitor/SettingModel'
    ss.dependency 'IESWebViewMonitor/WKWebView'
  end
  s.subspec 'ResourceIntercept' do |ss|
    ss.source_files = 'Classes/ResourceIntercept/**/*.{h,m,swift}'
    ss.dependency 'LarkWebViewContainer/Base'
  end
end
