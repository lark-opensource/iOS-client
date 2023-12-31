#
# Be sure to run `pod lib lint LarkActivityIndicatorView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "LarkActivityIndicatorView"
  s.version = '5.31.0.5463996'
  s.summary          = "LarkActivityIndicatorView EE iOS SDK组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/UI/LarkActivityIndicatorView'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  # s.resource_bundles = {
  #     'LarkActivityIndicatorView' => ['resources/*'] ,
  #     'LarkActivityIndicatorViewAuto' => 'auto_resources/*'
  # }

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  #attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  #}
end
