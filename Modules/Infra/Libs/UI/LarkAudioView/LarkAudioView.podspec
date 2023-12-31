#
# Be sure to run `pod lib lint LarkAudioView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "LarkAudioView"
  s.version          = "0.22.0"
  s.summary          = "LarkAudioView EE iOS SDK组件"

  s.description      = "Lark 语音播放组件"
  s.homepage = 'ssh://lichen.arthur@git.byted.org:29418/ee/ios-infra'
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "lichen.arthur@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  s.resource_bundles = {
      'LarkAudioView' => ['resources/*']
  }
  s.dependency 'SnapKit'
  s.dependency 'RichLabel'
  s.dependency 'LarkAudioKit'
  s.dependency 'UniverseDesignColor'
  s.dependency 'LarkExtensions'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'UniverseDesignIcon'
end
