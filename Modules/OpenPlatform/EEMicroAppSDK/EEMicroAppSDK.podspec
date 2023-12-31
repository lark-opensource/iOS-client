#
# Be sure to run `pod lib lint EEMicroAppSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EEMicroAppSDK'
  # alpha版本 a.b.c-alpha.x (x>=0), beta版本 a.b.c (c>=1)
  s.version = '5.31.0.5480923'
  s.summary          = 'EE开放平台小程序SDK'
  s.homepage         = 'git@code.byted.org:ee/microapp-iOS-sdk.git'
  s.author           = { 'yinyuan.0' => 'yinyuan.0@bytedance.com' }
  s.source           = { :git => 'git@code.byted.org:ee/microapp-iOS-sdk.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
#  s.source_files = 'Classes/**/*.{h,m,mm,swift}'
  s.source_files = [
          'Block/**/*.{h,m,mm,c,swift}',
          'Classes/**/*.{h,m,mm,swift}',
          'Gadget/**/*.{h,m,mm,c,swift}',
          'Infra/**/*.{h,m,mm,c,swift}',
          'OpenAPI/**/*.{h,m,mm,c,swift}',
          'OpenBusiness/**/*.{h,m,mm,swift}',
          'PackageManager/**/*.{h,m,mm,c,swift}'
  ]
  s.resource_bundles = { 'EEMicroAppSDK' => ['Assets/*'] }
  s.swift_version = '5.4'
  s.module_name  = 'EEMicroAppSDK'

  s.dependency 'EENavigator'
  s.dependency 'FLAnimatedImage', '>= 1.0.12'
  s.dependency 'JSONModel', '>= 1.7.0'
  s.dependency 'LKTracing'
  s.dependency 'LarkActionSheet'
  s.dependency 'LarkActivityIndicatorView'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkOPInterface'
  s.dependency 'LarkRustHTTP'
  s.dependency 'LarkTag'
  s.dependency 'LarkImageEditor'
  s.dependency 'LarkAssetsBrowser'
  s.dependency 'Masonry'
  s.dependency 'RustPB'
  s.dependency 'TTPlayerSDK'
  s.dependency 'TTRoute', '0.2.33'
  s.dependency 'TTVideoEngine'
  s.dependency 'TTMicroApp'
  s.dependency 'Kingfisher'
  s.dependency 'ByteWebImage'
  s.dependency 'OPSDK'
  s.dependency 'OPBlock'
  s.dependency 'LarkWebViewContainer'
  s.dependency 'OPGadget'
  s.dependency 'LarkKeyboardKit'
  s.dependency 'ECOInfra'
  s.dependency 'ECOInfra/ECOConfig'
  s.dependency 'LarkModel'
  s.dependency 'SSZipArchive'
  s.dependency 'OPWebApp'
  s.dependency 'LarkPrivacySetting'
  s.dependency 'OPDynamicComponent'
  s.dependency 'LarkEmotion'
  s.dependency 'OPFoundation'
  s.dependency 'LarkCoreLocation'
  s.dependency 'LarkStorage'
  s.dependency 'LarkSplitViewController'
  # 定制修改库发版方法:
  # https://ee.byted.org/ci/job/mini-program/job/ios/job/ios-engin-related-pods-tag/build
  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
      "bot": "d21dc24182994e0e87a89419a9cd7b9f"
  }
end
