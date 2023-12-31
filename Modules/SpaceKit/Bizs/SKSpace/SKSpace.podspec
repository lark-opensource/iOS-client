# frozen_string_literal: true

#
# Be sure to run `pod lib lint SKSpace.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'SKSpace'
  s.version = '5.31.0.5341924'
  s.summary          = 'CCM Space 业务'
  s.description      = 'Space/文件夹/权限/团队空间/模板等业务'
  s.homepage         = 'https://code.byted.org/ee/spacekit-ios/tree/develop/Bizs/SKSpace'

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "wuwenjian.weston": 'wuwenjian.weston@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.3'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp,xib}'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'SKCommon/Core'
  s.dependency 'SKFoundation'
  s.dependency 'SKUIKit'
  s.dependency 'SKResource'
  s.dependency 'SKWorkspace'
  s.dependency 'LarkDocsIcon'

  s.dependency 'HandyJSON'
  s.dependency 'SwiftProtobuf'
  s.dependency 'LarkRustClient'

  s.dependency 'Alamofire'
  s.dependency 'SwiftyJSON'
  s.dependency 'SnapKit'
  s.dependency 'lottie-ios'
  s.dependency 'Kingfisher'
  s.dependency 'KingfisherWebP'
  s.dependency 'ReachabilitySwift'
  s.dependency 'KeychainAccess'
  s.dependency 'SkeletonView'
  s.dependency 'SQLite.swift'
  s.dependency 'CryptoSwift'
  s.dependency 'ReSwift'
  s.dependency 'Swinject'
  s.dependency 'SQLiteMigrationManager.swift'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkUIKit'
  s.dependency 'YYCache'
  s.dependency 'LarkLocalizations'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'LarkRustHTTP'
  s.dependency 'EENavigator'
  s.dependency 'JTAppleCalendar'
  s.dependency 'LarkAudioKit'
  s.dependency 'SpaceInterface'
  s.dependency 'TTVideoEngine'
  s.dependency 'TTPlayerSDK'
  s.dependency 'MDLMediaDataLoader'
  s.dependency 'LarkReactionView'
  s.dependency 'LarkEmotion'
  s.dependency 'LarkMenuController'
  s.dependency 'LarkReactionDetailController'
  s.dependency 'mobilecv2'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkAlertController'
  s.dependency 'SSZipArchive'
  s.dependency 'OfflineResourceManager'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'LarkSnsShare'
  s.dependency 'LarkExtensions'

  s.dependency 'LarkMonitor'
  s.dependency 'LarkAppConfig'
  s.dependency 'SuiteAppConfig'
  s.dependency 'ESPullToRefresh'
  s.dependency 'LarkSplitViewController'
  s.dependency 'LarkCache'
  s.dependency 'LarkFileKit'
  s.dependency 'UGBanner'
  s.dependency 'UGReachSDK'
  s.dependency 'RxDataSources'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'UniverseDesignProgressView'
  s.dependency 'UniverseDesignCheckBox'
  s.dependency 'UniverseDesignTag'
  s.dependency 'UniverseDesignLoading'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'LarkIllustrationResource'

  s.dependency 'LarkLocalizations'
  s.dependency 'UGRCoreIntegration'

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
    test_spec.dependency 'RxTest'
    test_spec.dependency 'RxBlocking'
    test_spec.dependency 'SKDrive'
  end
end
