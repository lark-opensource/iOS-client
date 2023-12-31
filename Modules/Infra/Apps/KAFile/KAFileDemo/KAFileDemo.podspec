Pod::Spec.new do |s|
  s.name             = 'KAFileDemo'
  s.version          = '0.1.0-alpha.0'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  s.authors = {
    "name": 'email'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.source_files = 'src/**/*.{h,m,swift}'
  s.license          = 'MIT'

  s.dependency 'KAFileInterface'
  s.dependency 'Masonry'
end
