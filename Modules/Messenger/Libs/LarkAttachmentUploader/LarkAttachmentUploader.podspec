#
# Be sure to run `pod lib lint LarkTag.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LarkAttachmentUploader"
  s.version = '5.28.0.5328835'
  s.summary          = 'LarkAttachmentUploader EE iOS SDK组件'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "TODO: Add long description of the pod here."
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/Bizs/LarkAttachmentUploader'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "kongkaikai@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'

  s.dependency 'ByteWebImage'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkStorage/Sandbox'
end
