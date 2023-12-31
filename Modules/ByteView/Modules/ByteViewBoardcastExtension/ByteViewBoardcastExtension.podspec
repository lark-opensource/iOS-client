# frozen_string_literal: true

#
# Be sure to run `pod lib lint ByteViewBoardcastExtension.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'ByteViewBoardcastExtension'
  s.version = '5.30.0.5410491'
  s.summary          = 'ByteView Boardcast Extension on iOS'
  s.description      = 'ByteView Boardcast Extension on iOS'
  s.homepage         = 'https://github.com/ddeville/ByteViewBoardcastExtension'
  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "ruanmingzhe": 'ruanmingzhe@bytedance.com'
  }
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1.2'
  s.dependency 'ByteRtcScreenCapturer'
  s.dependency 'LarkExtensionServices'
  s.source_files = 'src/*.{swift,h,m}'
  s.subspec 'Configurations' do |cs|
    cs.source_files = 'src/configurations/**/*.{h,m,mm,swift}'
    cs.dependency 'LarkLocalizations'
    cs.resource_bundles = {
      'ByteViewBoardcastExtensionAuto' => ['auto_resources/**/*']
    }
  end
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }
  s.frameworks = 'Foundation'
  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'git@code.byted.org:ee/ByteView.iOS.git'
  }
end
