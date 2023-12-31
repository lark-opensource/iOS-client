Pod::Spec.new do |s|
  s.name             = 'WebBrowser'
  s.version = '5.31.0.5454293'
  s.summary          = '套件统一浏览器'
  s.homepage         = 'https://code.byted.org/ee/microapp-iOS-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'name' => 'luogantong' }
  s.source           = { :git => 'git@code.byted.org:ee/microapp-iOS-sdk.git', :tag => s.version.to_s }
  s.swift_version = "5.4"
  s.ios.deployment_target = '11.0'
  
  # 不要包含 RustPB 等 Lark 相关依赖 会用于单品等其他场景，千万不要依赖FG模块，FG模块依赖了Rust，如果不看注释胡乱依赖，需要revert代码，写case study，做复盘
  s.default_subspecs = ["Core"]
  
  s.source_files = 'src/**/*'
  s.resource_bundles = {
    'WebBrowser' => ['resources/*'],
    'WebBrowserAuto' => ['auto_resources/*']
  }
  
  s.subspec 'Core' do |sub|
    sub.dependency 'CookieManager'
    sub.dependency 'ECOInfra/ECOFoundation'
    sub.dependency 'ECOProbe'
    sub.dependency 'LarkAccountInterface'
    sub.dependency 'LarkBadge'    # Badge 显示
    sub.dependency 'LarkContainer'
    sub.dependency 'LarkCloudScheme'
    sub.dependency 'LarkFoundation'
    sub.dependency 'LarkLocalizations'
    sub.dependency 'LarkOPInterface'
    sub.dependency 'LarkSetting'
    sub.dependency 'LarkSuspendable'
    sub.dependency 'LarkUIKit/Base'   # 基础UI组件
    sub.dependency 'LarkUIKit/Common' # 资源
    sub.dependency 'LarkUIKit/LoadPlaceholder'
    sub.dependency 'LarkWebViewContainer'
    sub.dependency 'LarkWebviewNativeComponent'
    sub.dependency 'LarkSceneManager'
    sub.dependency 'LarkSplitViewController'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'LKLoadable'
    sub.dependency 'OPFoundation'
    sub.dependency 'SnapKit'
    sub.dependency 'UniverseDesignColor'
    sub.dependency 'UniverseDesignDialog'
    sub.dependency 'UniverseDesignEmpty'
    sub.dependency 'UniverseDesignIcon'
    sub.dependency 'UniverseDesignInput'
    sub.dependency 'UniverseDesignLoading'
    sub.dependency 'UniverseDesignProgressView'
    sub.dependency 'UniverseDesignTheme'
    sub.dependency 'UniverseDesignToast'
    sub.dependency 'ZeroTrust/Base'
    sub.dependency 'LarkMonitor'
    sub.dependency 'LarkDebugExtensionPoint'
    sub.dependency 'LarkQuickLaunchInterface'
    sub.dependency 'LarkQuickLaunchBar'
    sub.dependency 'RxRelay'
    sub.dependency 'LarkAIInfra'
  end
  
  s.subspec 'KA' do |ka|
     ka.dependency 'LKWebContainerExternal'
  end
  
  s.test_spec 'Tests' do |ts|
    ts.source_files = 'Tests/**/*.{swift,h,m,mm}'#根据单测代码决定
    ts.requires_app_host = true
    ts.xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym', #需要dsym
      'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_CONFIGURATION_BUILD_DIR}/OPUnitTestFoundation" "${PODS_CONFIGURATION_BUILD_DIR}/RxBlocking" "${PODS_CONFIGURATION_BUILD_DIR}/RxTest" "${PODS_CONFIGURATION_BUILD_DIR}/OCMock"',
      'OTHER_LDFLAGS' => '$(inherited) -ObjC'
    }

    ts.scheme = {
      :code_coverage => true,#开启覆盖率
      :environment_variables => {'UNIT_TEST' => '1'},#单测启动环境变量
      :launch_arguments => [] #测试启动参数
    }

    # 这里的依赖同时也要加在 xcconfig FRAMEWORK_SEARCH_PATHS
    ts.dependency 'OPUnitTestFoundation'
    ts.dependency 'RxBlocking'
    ts.dependency 'RxTest'
    
  end
end
