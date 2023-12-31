# frozen_string_literal: true

#
# Be sure to run `pod lib lint EEPodInfoDebugger.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'EEPodInfoDebugger'
  s.version = '5.27.0.5296218'
  s.summary          = '让接入方能查看读取pod引入的各组件版本号。'
  s.description      = '主要使用场景作为接入方的调试中心的一个模块，用于快速获取pod引入的组件的版本号。'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/EEFoundation/tree/master/Libs/EEPodInfoDebugger'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "liutefeng": 'liutefeng@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.preserve_paths = ['script']
  s.resource_bundles = {
      'EEPodInfoDebugger' => ['resources/*'] ,
      #'EEPodInfoDebuggerAuto' => 'auto_resources/*'
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'
  s.dependency 'SnapKit'
  s.dependency 'CryptoSwift'
  s.dependency 'LarkFoundation/Debug'

  # 脚本，在编译前会执行的脚本。用于通过lock文件生成可读的plist文件
  # script_path = File.expand_path("./src/script/generatePodInfo.rb", File.dirname(__FILE__))
  # script_txt = File.open(script_path)

  s.script_phase = { :name => 'generate podinfo datasource', :script =>
    'which -s orbit && orbit ruby "${PODS_TARGET_SRCROOT}/script/generatePodInfo.rb" || ruby "${PODS_TARGET_SRCROOT}/script/generatePodInfo.rb"',
    :execution_position => :before_compile,
    :shell_path => '/bin/bash',
  }


  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "c1ffe8f38ee74ce0bc5453fa26dffdf1"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'ssh://git.byted.org:29418/ee/EEFoundation'
  }
end
