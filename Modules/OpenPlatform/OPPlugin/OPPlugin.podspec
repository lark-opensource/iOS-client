# frozen_string_literal: true

#
# Be sure to run `pod lib lint OPPlugin.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'OPPlugin'
  s.version = '5.31.0.5454779'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'email'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.4'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'OPPlugin' => ['resources/*.lproj/*', 'resources/*'],
      'OPPluginAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'
  s.dependency 'TTMicroApp'
  s.dependency 'LarkOPInterface'
  s.dependency 'LarkOpenPluginManager'
  s.dependency 'LarkOpenAPIModel'
  s.dependency 'FigmaKit'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignFont'
  s.dependency 'OPSDK'
  s.dependency 'ECOInfra'
  s.dependency 'LarkAccountInterface'
  s.dependency 'WebBrowser'
  s.dependency 'ByteWebImage'
  s.dependency 'LarkSplitViewController'
  s.dependency 'LarkWebviewNativeComponent'
  s.dependency 'LarkPrivacySetting'
  s.dependency 'LarkLocationPicker'
  s.dependency 'OPDynamicComponent'
  s.dependency 'LarkCoreLocation'
  s.dependency 'LarkContainer'
  s.dependency 'LarkUIKit'
  s.dependency 'QRCode'
  s.dependency 'TTVideoEditor/VERecorderMode'
  s.dependency 'TTVideoEditor/VEScan'
  s.dependency 'LarkVideoDirector/Lark'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'OPPluginBiz'
  
  s.dependency 'TTReachability'
  s.dependency 'ECOProbe'
  s.dependency 'ECOInfra'
  
  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => 'ENABLE_SCENE_DETECT=1 ENABLE_LUMA_DETECT=1'
  }

  %w[Alamofire
    ECOInfra
    ECOProbe
    ECOProbeMeta
    EENavigator
    LKCommonsLogging
    LarkAccountInterface
    LarkAppConfig
    LarkContainer
    LarkCoreLocation
    LarkEnv
    LarkFeatureGating
    LarkFoundation
    LarkLocalizations
    LarkLocationPicker
    LarkOPInterface
    LarkOpenAPIModel
    LarkOpenPluginManager
    LarkPrivacySetting
    LarkRustClient
    LarkRustHTTP
    LarkSetting
    LarkSplitViewController
    LarkTag
    LarkUIKit
    OPFoundation
    OPSDK
    RustPB
    RxSwift
    SnapKit
    SwiftyJSON
    Swinject
    TTMicroApp
    TTReachability
    ThreadSafeDataStructure
    UniverseDesignColor
    UniverseDesignDialog
    UniverseDesignIcon
    UniverseDesignTheme 
    WebBrowser
    OPPluginBiz
    ].each do |e|
      s.dependency e
    end
  
  s.test_spec 'Tests' do |ts|
    ts.source_files = 'Tests/**/*.{swift,h,m,mm}'#根据单测代码决定
    ts.requires_app_host = true
    ts.xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym', #需要dsym
      'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_CONFIGURATION_BUILD_DIR}/OPUnitTestFoundation" "${PODS_CONFIGURATION_BUILD_DIR}/OCMock"',
      'OTHER_LDFLAGS' => '$(inherited) -ObjC'
    }
    ts.resource_bundles = {
        'TestsResource' => ['Tests/Resources/*.{json,zip}']
    }

    ts.scheme = {
      :code_coverage => true,#开启覆盖率
      :environment_variables => {'UNIT_TEST' => '1'},#单测启动环境变量
      :launch_arguments => [] #测试启动参数
    }

    ts.dependency 'OPUnitTestFoundation'
    # ts.dependency 'MockingbirdFramework'
    
  end
  
  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'Required.'
  }
end
