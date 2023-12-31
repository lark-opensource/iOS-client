#
# Be sure to run `pod lib lint LarkReleaseConfig.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LarkReleaseConfig"
  s.version = '5.29.0.5377785'
  s.summary          = "LarkReleaseConfig EE iOS SDK组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Bizs/LarkReleaseConfig'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "刘晚林" => "liuwanlin@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
    "bot": "d971d6ce5f6245de9a41c413dcb253d1"
  }

end
