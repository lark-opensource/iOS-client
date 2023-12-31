#
#  Be sure to run `pod spec lint ByteViewRTCRenderer.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name                  = "ByteViewRTCRenderer"
  spec.version = '5.31.0.5474100'
  spec.summary               = "ByteView RTC Renderer"
  spec.description           = "ByteView RTC Renderer"

  spec.homepage              = "https://code.byted.org/ee/ByteView.iOS"
  spec.license               = "MIT"
  spec.author                = { "刘建龙" => "liujianlong@bytedance.com" }

  spec.ios.deployment_target = '11.0'
  spec.source                = { git: 'generated_by_eesc.zip', tag: spec.version.to_s }
  spec.public_header_files   = "src/include/public/*.h"
  spec.source_files          = "src", "src/**/*.{h,m,mm,swift,cpp,hpp}"
  spec.private_header_files  = "src/**/*.hpp", "src/include/private/*.h"
  spec.resource_bundles = {
    'byteview_renderer' => ['src/**/*.metal']
  }
  spec.frameworks            = "UIKit"

  spec.requires_arc          = true

end
