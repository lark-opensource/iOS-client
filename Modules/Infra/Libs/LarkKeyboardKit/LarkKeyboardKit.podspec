# frozen_string_literal: true

#
# Be sure to run `pod lib lint KeyboardKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = 'LarkKeyboardKit'
  s.version          = "0.21.0"
  s.summary          = 'iOS system Keyboard Kit'
  s.description      = 'iOS system Keyboard Kit'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  s.authors = {
    "lichen.arthur": 'lichen.arthur@bytedance.com'
  }

  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxRelay'
  s.dependency 'LKCommonsLogging'

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'Required.'
  }
end
