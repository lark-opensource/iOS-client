# coding: utf-8
Pod::Spec.new do |s|
  s.name         = "LKCommonsLogging"
  s.version = '5.30.0.5405807'
  s.summary      = "统一日志接口"
  s.description  = <<-DESC
随着业务的发展，会将越来越多的业务逻辑、组件拆分独立出来，成为单独的静态库或pods。 这些pods均依赖日志组件提供输出日志的功能。为了统一标准化各pods库的日志记录方式，并且为应用程序提供更多的日志输出控制权。参考 apache commons-logging 实现了一套简单的、基于swift的日志输出接口。
  DESC
  s.homepage     = "https://ee.byted.org/madeira/browse/ee/EEFoundation/tree/master/Libs/LKCommonsLogging"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "lvdaqian" => "lvdaqian@bytedance.com" }
  s.ios.deployment_target = "8.0"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => "git@code.byted.org:ee/EEFoundation", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
  s.frameworks  = "Foundation"
  s.swift_version = '5.0'

  s.xcconfig = {
  'SWIFT_OPTIMIZATION_LEVEL' => '-Osize',
  'GCC_OPTIMIZATION_LEVEL'  => 'z',
  'DEAD_CODE_STRIPPING' => 'YES',
  'DEPLOYMENT_POSTPROCESSING' => 'YES',
  'STRIP_INSTALLED_PRODUCT' => 'YES',
  'STRIP_STYLE' => 'all',
  'STRIPFLAGS' => '-u',
  'GCC_SYMBOLS_PRIVATE_EXTERN' => 'YES'
  }

  attributes_hash = s.instance_variable_get("@attributes_hash")
  attributes_hash['extra'] = {
    "git_url": "ssh://git.byted.org:29418/ee/EEFoundation"
  }
end
