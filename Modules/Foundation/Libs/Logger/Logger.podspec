# coding: utf-8
Pod::Spec.new do |s|
  s.name          = 'Logger'
  s.version = '5.31.0.5463996'
  s.authors        = {
    'Guilin Cui' => 'cuiguilin@bytedance.com',
    'Chen Li' => 'lichen.arthur@bytedance.com'
  }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/EEFoundation/tree/master/Libs/Logger'
  s.summary       = '提供日志功能：根据Category映射到不同的Appenders集合，Appender来处理具体的日志事件'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/EEFoundation', :tag => s.version.to_s }

  s.platform      = :ios
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'

  s.default_subspec = ['Core']

  s.subspec 'Core' do |sub|
    sub.source_files  = 'Logger/Core/**/*.{swift}'
    sub.dependency 'LarkFoundation'
    sub.dependency 'LKCommonsLogging'
  end

  s.subspec 'Lark' do |sub|
    sub.source_files  = 'Logger/Lark/**/*.{swift,h}'
    sub.dependency 'Logger/Core'
    sub.dependency 'LKMetric'
    sub.dependency 'BDAlogProtocol'
    sub.dependency 'LarkStorage'
  end

  attributes_hash = s.instance_variable_get("@attributes_hash")
  attributes_hash['extra'] = {
    "git_url": "ssh://git.byted.org:29418/ee/EEFoundation"
  }
end
