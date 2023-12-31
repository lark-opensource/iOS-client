# coding: utf-8
#
# Be sure to run `pod lib lint EENavigator.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "EENavigator"
  s.version = '5.31.0.5463996'
  s.summary          = "EENavigator EE iOS SDK组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "EENavigator"

  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/EEFoundation/tree/master/Libs/EENavigator'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "liuwanlin@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEFoundation"}
  s.ios.deployment_target = '11.0'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.swift_version = '5.1'
  s.source_files = 'src/**/*.{swift,h,m}'
  s.dependency 'SuiteCodable'
  s.dependency 'EETroubleKiller'
  s.dependency 'EEAtomic'
  s.dependency 'LKLoadable'
  s.dependency 'LKCommonsTracker'

  # s.debug_dependency 'SnapKit'

  attributes_hash = s.instance_variable_get("@attributes_hash")
  attributes_hash['extra'] = {
    "git_url": "ssh://git.byted.org:29418/ee/EEFoundation"
  }
end
