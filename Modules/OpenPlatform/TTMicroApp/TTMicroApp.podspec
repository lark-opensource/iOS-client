#
# Be sure to run `pod lib lint TTMicroApp.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TTMicroApp'
  # alpha版本 a.b.c-alpha.x (x>=0), beta版本 a.b.c (c>=1)
  s.version = '5.31.0.5465229'
  s.summary          = '字节跳动开放平台小程序SDK'
  s.description      = <<-DESC
  字节跳动开放平台小程序
  DESC
  s.homepage         = 'https://code.byted.org/TTIOS/TTMicroApp'
  s.author           = { 'zengruihuan' => 'zengruihuan@bytedance.com' }
  s.source           = { :git => "git@code.byted.org:TTIOS/TTMicroApp.git", :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.prefix_header_contents = '#import "coder.h"'
  s.swift_version = '5.4'

  # 解决引用的Heimdallr导致的编译不通过的问题：/Heimdallr/Classes/Mach/tools/HMDAsyncThread.h:76:10: Include of non-modular header inside framework module 'Heimdallr.HMDAsyncThread': '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.4.sdk/usr/include/mach/arm/thread_state.h'
  s.pod_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }

  s.test_spec 'Tests' do |ts|
    ts.source_files = 'Tests/**/*.{swift,m}'
    ts.requires_app_host = true
    ts.xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym' #需要dsym
    }

    ts.scheme = {
      :code_coverage => true,#开启覆盖率
      :environment_variables => {'UNIT_TEST' => '1'},#单测启动环境变量
      :launch_arguments => [] #测试启动参数
    }
  end

  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkWebViewContainer'
  s.dependency 'LarkUIKit/Menu'
  s.dependency 'ECOInfra'
  s.dependency 'UniverseDesignNotice'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkAppConfig'
  s.dependency 'LarkContainer'
  s.dependency 'FigmaKit'
  s.dependency 'LarkWebviewNativeComponent'
  s.dependency 'OPJSEngine'
  s.dependency 'LarkMonitor'
  s.dependency 'UniverseDesignFont'
  s.dependency 'LarkClean'
  s.dependency 'LarkSceneManager'

  # ------------------------ 核心公共模块 Common ----------------------- #
  s.subspec 'Core' do |ss|
    ss.source_files = [
      'Gadget/**/*.{h,m,swift}',
      'HTML5/**/*.{h,m,mm,c,swift}',
      'OpenAPI/**/*.{h,m,mm,c,swift}',
      'OpenBusiness/**/*.{h,m,mm,c,swift}',
      'PackageManager/**/*.{h,m,mm,c,swift}',
      'Timor/Core/**/*.{h,m,mm,c,swift}'
    ]

    # TODO: exclude BDPHttpDownloadTask+BrSupport.m if no ttnet, or make this subspec
    ss.private_header_files = 'PackageManager/Download/brotli/*'
    
    ss.requires_arc = [
      'Gadget/**/*.{h,m,swift}',
      'HTML5/**/*.{h,m,mm,c,swift}',
      'OpenAPI/**/*.{h,m,mm,c,swift}',
      'OpenBusiness/**/*.{h,m,mm,c,swift}',
      'PackageManager/**/*.{h,m,mm,c,swift}',
      'Timor/Core/**/*.{h,m,mm,c,swift}'
    ]

    ss.resource_bundles = {
        'TimorAssetBundle' => ['Timor/Resources/*.{xcassets,bundle}',
                               'Timor/Resources/Others/**/*']
    }

    ss.dependency 'BDWebImage'
    ss.dependency 'FMDB'
    ss.dependency 'JSONModel'
    ss.dependency 'KVOController'
    ss.dependency 'LarkLocalizations'
    ss.dependency 'LarkOPInterface'
    ss.dependency 'Masonry'
    ss.dependency 'SSZipArchive'
    ss.dependency 'SocketRocket'
    ss.dependency 'TTNetworkManager'
    ss.dependency 'libwebp'
    ss.dependency 'OPSDK'
    ss.dependency 'LarkMedia'
    ss.dependency 'LarkInteraction'
    ss.dependency 'LarkOpenPluginManager'
    ss.dependency 'LKLoadable'
    ss.dependency 'FigmaKit'
    ss.dependency 'UniverseDesignIcon'
    ss.dependency 'LarkCache/Core'
    ss.dependency 'LibArchiveKit'
		ss.dependency 'OPBlockInterface'
    ss.dependency 'TTMicroApp/Infra'
    ss.dependency 'TTVideoEngine'
    ss.dependency 'ReactiveObjC'
    ss.dependency 'LarkRustHTTP'
    ss.dependency 'OPPluginManagerAdapter'

    # H5-WebView 公共模块
    ss.subspec 'HTML5' do |sss|
      sss.requires_arc = true;
      sss.source_files = ['HTML5/**/*.{h,m,mm,c,swift}']
    end

    ss.ios.framework = ['ReplayKit', 'MobileCoreServices', 'Photos', 'CoreLocation', 'WebKit']
  end

  # ---------------------- 卡片引擎 ----------------------- #
  s.subspec 'Card' do |ss|
    ss.dependency 'Lynx'
    ss.dependency 'TTMicroApp/Core'
    ss.dependency 'SnapKit'
    ss.source_files = ['Widget/**/*.{h,m,mm,c,swift}']
  end

  s.subspec 'Infra' do |ss|
    ss.source_files = ['Infra/**/*.{h,m,mm,c,swift}']
    ss.dependency 'LarkLocalizations'
    ss.dependency 'OPFoundation'

  end

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
      'bot' => 'd21dc24182994e0e87a89419a9cd7b9f'
  }
end
