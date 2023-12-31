#
# Be sure to run `pod lib lint QRCode.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "QRCode"
  s.version = '5.31.0.5470752'
  s.summary          = "QRCode EE iOS SDK组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/QRCode'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.swift_version = "5.1"
  
  s.resource_bundles = {
      'QRCode' => ['resources/*'] ,
      'QRCodeAuto' => 'auto_resources/*'
  }
  
  s.dependency 'LarkLocalizations'
  
  s.subspec 'Biz' do |sub|
    sub.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
    
    sub.dependency 'QRCode/QRCodeTool'
    sub.dependency 'LarkLocalizations'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'LKCommonsTracker'
    sub.dependency 'Homeric'
    sub.dependency 'RxSwift'
    sub.dependency 'RxCocoa'
    sub.dependency 'SnapKit'
    sub.dependency 'smash/qrcode'
    sub.dependency 'LarkUIKit'
    sub.dependency 'LarkFoundation'
    sub.dependency 'LarkExtensions'
    sub.dependency 'LarkSetting'
    sub.dependency 'RichLabel'
    sub.dependency 'LarkAssetsBrowser'
    sub.dependency 'UniverseDesignIcon'
    sub.dependency 'UniverseDesignShadow'
    sub.dependency 'ByteWebImage'
    sub.dependency 'LarkVideoDirector/Lark'
    sub.dependency 'LarkImageEditor'
    sub.dependency 'LarkUIKit'
    sub.dependency 'ThreadSafeDataStructure'
    sub.dependency 'LarkSensitivityControl/API/Camera'
    sub.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => [
      'ENABLE_LUMA_DETECT=1'
    ]}
  end

  s.subspec 'QRCodeTool' do |sub|
    sub.source_files = 'QRCodeTool/**/*.{swift,h,m,mm,cpp}'
  end
  
  s.subspec 'Mock' do |sub|
    sub.dependency 'QRCode/QRCodeTool'
    sub.source_files = [
      'Mock/**/*.{swift,h,m,mm,cpp}',
      'src/ScanCodeService.swift'
    ]

    sub.dependency 'LarkUIKit'
  end

  s.default_subspecs = ['QRCodeTool'] #, 'Biz']
  
  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  #attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  #}
end
