Pod::Spec.new do |s|
  s.name             = 'EcosystemWeb'
  s.version = '5.31.0.5474886'
  s.summary          = 'Ecosystem Client Native Web Business'
  s.description      = 'Ecosystem Client Native Web Business'
  s.homepage         = 'https://code.byted.org/ee/microapp-iOS-sdk'
  s.authors = {
    "luogantong": 'luogantong@bytedance.com'
  }
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.4'
  s.source_files = 'src/**/*.{swift,h,m}'
  s.resource_bundles = {
      'EcosystemWeb' => ['resources/*.lproj/*', 'resources/*'],
      'EcosystemWebAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }
  
  s.dependency 'AnimatedTabBar'
  s.dependency 'ByteWebImage'
  s.dependency 'CookieManager'
  s.dependency 'ECOInfra'
  s.dependency 'ECOProbe'
  s.dependency 'ECOProbeMeta'
  s.dependency 'EENavigator'
  s.dependency 'FigmaKit'
  s.dependency 'HTTProtocol'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkAppConfig'
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkCompatible'
  s.dependency 'LarkContainer'
  s.dependency 'LarkExtensions'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkGuide'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkOpenAPIModel'
  s.dependency 'LarkOpenPluginManager'
  s.dependency 'LarkOPInterface'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkSceneManager'
  s.dependency 'LarkSplitViewController'
  s.dependency 'LarkSetting'
  s.dependency 'LarkTab'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkWebViewContainer'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKLoadable'
  s.dependency 'OPFoundation'
  s.dependency 'OPPlugin'
  s.dependency 'OPSDK'
  s.dependency 'OPWebApp'
  s.dependency 'RustPB'
  s.dependency 'RxCocoa'
  s.dependency 'RxRelay'
  s.dependency 'RxSwift'
  s.dependency 'SnapKit'
  s.dependency 'SuiteAppConfig'
  s.dependency 'Swinject'
  s.dependency 'TTMicroApp' # 这个需要删掉
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignLoading'
  s.dependency 'UniverseDesignMenu'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'UniverseDesignToast'
  s.dependency 'WebBrowser'
  s.dependency 'LarkEMM'
  s.dependency 'LarkQuickLaunchInterface'
  s.dependency 'LarkQuickLaunchBar'
  s.dependency 'LarkOpenWorkplace'
  s.dependency 'LarkKeepAlive'
  s.dependency 'LarkAIInfra'
  
  s.test_spec 'Tests' do |ts|
    ts.source_files = 'Tests/**/*.{swift,h,m,mm}'#根据单测代码决定
    ts.requires_app_host = true
    ts.xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym', #需要dsym
      'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_CONFIGURATION_BUILD_DIR}/OPUnitTestFoundation" "${PODS_CONFIGURATION_BUILD_DIR}/OCMock"',
      'OTHER_LDFLAGS' => '$(inherited) -ObjC'
    }

    ts.scheme = {
      :code_coverage => true,#开启覆盖率
      :environment_variables => {'UNIT_TEST' => '1'},#单测启动环境变量
      :launch_arguments => [] #测试启动参数
    }

    ts.dependency 'OPUnitTestFoundation'
    
  end

  attributes_hash = s.instance_variable_get('@attributes_hash')
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'Required.'
  }
end
