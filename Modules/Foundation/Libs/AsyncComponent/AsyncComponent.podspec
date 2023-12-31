# coding: utf-8
#
# Be sure to run `pod lib lint AsyncComponent.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "AsyncComponent"
  s.version = '5.28.0.5358506'
  s.summary          = "AsyncComponent EE iOS SDK组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/AsyncComponent'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Naixor" => "qihongye@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.static_framework = true
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  # s.resource_bundles = {
  #     'AsyncComponent' => ['resources/*'] ,
  #     'AsyncComponentAuto' => 'auto_resources/*'
  # }
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }

  s.dependency 'EEFlexiable'
  s.dependency 'RichLabel'
  s.dependency 'LKRichView'
  s.dependency "Yoga", "<= 1.9.0"
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'EEAtomic'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'UniverseDesignCardHeader'
  s.dependency 'LKCommonsTracker'

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
    "bot": "d2e5933f75ad401a9e72a2502c2dc8b5"
  }
end
