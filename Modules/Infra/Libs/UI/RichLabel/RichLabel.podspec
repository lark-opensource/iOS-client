# coding: utf-8
#
# Be sure to run `pod lib lint RichLabel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "RichLabel"
  s.version = '5.31.0.5463996'
  s.summary          = "RichLabel EE iOS SDK组件"
  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/UI/RichLabel'
  s.license          = 'MIT'
  s.author           = { "Naixor" => "qihongye@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'

  s.dependency 'LarkCompatible'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignFont'
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC'
  }

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
    "bot": "2652640c7cd1477fbf5b68fcc36cb101"
  }
end
