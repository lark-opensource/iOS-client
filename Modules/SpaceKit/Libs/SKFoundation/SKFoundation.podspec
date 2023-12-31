# frozen_string_literal: true

#
# Be sure to run `pod lib lint SKFoundation.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name = 'SKFoundation'
  s.version = '5.31.0.5341924'
  s.summary = 'SpaceKit 业务无关的基础组件'
  s.description = '包含Network、打点、Logger、Extension、Utility等'
  s.homepage = 'https://code.byted.org/lark/iOS-client/tree/develop/Modules/SpaceKit/Libs/SKFoundation'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "lijuyou": 'lijuyou@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.3'


  s.preserve_paths = ['Scripts', 'SKFoundation.podspec']

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  # s.resource_bundles = {
  #     'SKFoundation' => ['resources/*.lproj/*' 'resources/*'] ,
  #     'SKFoundationAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  # }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'SKResource'
  s.dependency 'Alamofire'
  s.dependency 'ReachabilitySwift'
  s.dependency 'LarkRustHTTP'
  s.dependency 'HTTProtocol'
  s.dependency 'SSZipArchive'
  s.dependency 'LibArchiveKit'
  s.dependency 'CryptoSwift'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'SwiftyJSON'
  s.dependency 'LarkUIKit'
  s.dependency 'EENavigator'
  s.dependency 'OfflineResourceManager'
  s.dependency 'ESPullToRefresh'
  s.dependency 'LarkTimeFormatUtils'
  s.dependency 'UniverseDesignColor'
  s.dependency 'RustSDK'
  s.dependency 'LarkSetting'
  s.dependency 'LarkExtensions'
  s.dependency 'LarkMonitor'
  s.dependency 'LarkStorage'

   ### configs
   s.xcconfig     = {
    'ENABLE_BITCODE' => 'NO',
    'OTHER_LDFLAGS' => '-ObjC'
   }

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'git@code.byted.org:ee/spacekit-ios.git'
  }
   # 单元测试
   s.test_spec 'Tests' do |test_spec|
    test_spec.test_type = :unit
    test_spec.source_files = 'tests/**/*.{swift,h,m,mm,cpp}'
    test_spec.resources = 'tests/Resources/*'
    test_spec.xcconfig = {
        'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
    }
    test_spec.scheme = {
        :code_coverage => true,
        :environment_variables => {'UNIT_TEST' => '1'},
        :launch_arguments => []
    }
    test_spec.dependency 'OHHTTPStubs/Swift'
    test_spec.dependency 'SwiftyJSON'
  end
end
