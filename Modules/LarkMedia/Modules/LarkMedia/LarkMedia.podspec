# Be sure to run `pod lib lint LarkMedia.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LarkMedia"
  s.version          = '7.1.0'
  s.summary          = "Lark 媒体资源管理组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Lark 媒体资源（音频录制、音频播放、摄像头录制）管理组件。设计方案如下
https://bytedance.feishu.cn/docx/doxcnCWWyShNCEQVhfzl27UcL7f
                       DESC
  s.homepage         = "https://code.byted.org/vc/LarkMedia"
  s.license          = 'MIT'
  s.author           = { "Video Conference Product Engineering" => "zhoufeng.ford@bytedance.com" }
  s.source           = { :git => "git@code.byted.org:iOS_Library/lark_source_repo.git"}
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'

  s.ios.framework  = 'AVFoundation'

  s.dependency 'LKCommonsLogging'

  s.default_subspec = 'Core'

  s.subspec 'API' do |cs|
    cs.dependency 'LKCommonsLogging'
    cs.dependency 'EEAtomic'
    cs.source_files = 'src/API/**/*.{swift,h,m,mm,cpp}'
  end

  s.subspec 'Common' do |cs|
    cs.dependency 'LarkMedia/API'
    cs.source_files = 'src/Common/**/*.{swift,h,m,mm,cpp}'
  end

  s.subspec 'Core' do |cs|
    cs.dependency 'LarkMedia/Common'
    cs.source_files = 'src/Core/**/*.{swift,h,m,mm,cpp}'
  end

  s.subspec 'Rx' do |cs|
    cs.dependency 'LarkMedia/Common'
    cs.dependency 'RxSwift'
    cs.dependency 'RxCocoa'
    cs.source_files = 'src/Rx/**/*.{swift,h,m,mm,cpp}'
  end

  s.subspec 'Track' do |cs|
    cs.dependency 'LarkMedia/Common'
    cs.dependency 'LKCommonsTracker'
    cs.source_files = 'src/Track/**/*.{swift,h,m,mm,cpp}'
  end

  s.subspec 'Load' do |cs|
    cs.dependency 'LarkMedia/Hook'
    cs.source_files = 'src/Load/**/*.{swift,h,m,mm,cpp}'
  end

  s.subspec 'Hook' do |cs|
    cs.dependency 'LarkMedia/Common'
    cs.dependency 'BDFishhook', '>= 0.1.1'
    cs.source_files = 'src/Hook/**/*.{swift,h,m,mm,cpp}'
  end

  s.subspec 'Debug' do |cs|
    cs.source_files = 'src/Debug/**/*.{swift,h,m,mm,cpp}'
  end
end
