#
# Be sure to run `pod lib lint NativeAppPublicKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NativeAppPublicKit'
  s.version          = '5.31.0.1'
  s.summary          = 'A short description of NativeAppPublicKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "NativeAppPublicKit alchemy public pod, will be build to a dynamic pod to customer."

  s.homepage         = 'https://github.com/廉金涛/NativeAppPublicKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '廉金涛' => 'lianjintao@bytedance.com' }
  s.source           = { :git => 'https://github.com/廉金涛/NativeAppPublicKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'
  s.swift_version = "5.3"

  s.source_files = 'NativeAppPublicKit/Classes/**/*'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }

  # s.resource_bundles = {
  #   'NativeAppPublicKit' => ['NativeAppPublicKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end
