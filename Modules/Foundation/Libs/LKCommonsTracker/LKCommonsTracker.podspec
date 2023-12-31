# coding: utf-8

Pod::Spec.new do |s|
  s.name             = "LKCommonsTracker"
  s.version = '5.27.0.5300226'
  s.summary          = "埋点组件，封装了Tea和Slardar"
  s.description      = "埋点组件，封装了Tea和Slardar。提供统一的post方法来进行事件埋点"
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/EEFoundation/tree/master/Libs/LKCommonsTracker'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.authors          = {
    'Chen Li' => 'lichen.arthur@bytedance.com',
    'Guilin Cui' => 'cuiguilin@bytedance.com'
  }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEFoundation"}
  s.ios.deployment_target = '11.0'
  s.swift_version    = '5.0'
  s.static_framework = true
  s.source_files     = 'src/**/*.{swift}'
  s.dependency 'ThreadSafeDataStructure'

  attributes_hash    = s.instance_variable_get("@attributes_hash")
  attributes_hash['extra'] = {
    "git_url": "ssh://git.byted.org:29418/ee/EEFoundation"
  }
end
