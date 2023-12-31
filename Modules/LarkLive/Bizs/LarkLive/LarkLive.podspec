#
# Be sure to run `pod lib lint ByteView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'LarkLive'
  s.version = '5.31.0.5463996'
  s.summary          = 'An iOS Module of ByteView Project. Which will provide basic fucti'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
办公套件中会议系统，代号 ByteView。 本仓库为其 iOS 平台组件库。
                       DESC

  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ByteView.iOS/tree/master/'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lvdaqian' => 'lvdaqian@bytedance.com' }
  s.source           = { :git => 'git@code.byted.org:ee/ByteView.iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.swift_version = '5.0'

  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkLive' => ['resources/*.lproj/*', 'resources/*'],
      'LarkLiveAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }

  s.dependency 'LKCommonsLogging'
  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'RxCocoa', '~> 5.0'
  s.dependency 'Action', '~> 4.0'
  s.dependency 'SnapKit', '~> 5.0'
  s.dependency 'NSObject+Rx'
  s.dependency 'RxAutomaton'
  s.dependency 'RxDataSources'
  s.dependency 'SwiftyJSON'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkRustClient/Interface'
  s.dependency 'LKCommonsTracker'
  s.dependency 'RustPB'
  s.dependency 'RoundedHUD'
  s.dependency 'Homeric'
  s.dependency 'LarkAccountInterface'
  s.dependency 'Alamofire'
  s.dependency 'LarkWebViewContainer' #套件统一WebView
  s.dependency 'AppReciableSDK'
  s.dependency 'ServerPB'
  s.dependency 'LarkLiveInterface'
  s.dependency 'LarkSuspendable'
  s.dependency 'MinutesFoundation'
  s.dependency 'Heimdallr'
  s.dependency 'EENavigator'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkContainer'
  s.dependency 'ECOInfra'
  s.dependency 'LarkWebViewContainer'
  s.dependency 'LarkSnsShare'
  s.dependency 'CryptoSwift'
  s.dependency 'LarkTracker'
  
  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
    "bot": "d65ec628edd1434c885b2609210e941f"
  }

end
