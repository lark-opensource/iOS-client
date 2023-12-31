#
# Be sure to run `pod lib lint Whiteboard.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Whiteboard'
  s.version          = '0.0.1'
  s.summary          = 'The interface of byteview'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
The interface of byteview. It should not dependence any other pod.
                       DESC

  s.homepage         = 'https://code.byted.org/vc/Whiteboard'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ruanmingzhe' => 'ruanmingzhe@bytedance.com' }
  s.source           = { :git => 'https://code.byted.org/vc/Whiteboard.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.source_files = 'src/**/*'
  s.dependency 'WbLib'
  s.dependency 'RxRelay'
  s.dependency 'SnapKit'
  s.dependency 'ByteViewCommon'
  s.dependency 'ByteViewUDColor'
  s.dependency 'ByteViewNetwork'
  s.dependency 'ByteViewTracker'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'ByteViewUI'
  s.dependency 'UniverseDesignToast'
  s.dependency 'LarkAlertController'
  s.resource_bundles = {
    'Whiteboard' => ['resources/*.lproj/*', 'resources/*'],
    'WhiteboardAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
