# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkKAFKMS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkKAFKMS'
  s.version          = '0.1.0-alpha.0'
  s.summary          = '集成第三方加密 SDK'
  s.description      = '用于 KA 打包集成第三方加密 SDK https://bytedance.feishu.cn/docx/doxcn1dNigK76jJGksznYdUJrLg'
  s.homepage         = 'https://code.byted.org/lark/ios-infra/tree/feature/zjc/privateChatFunctionForbidden/Bizs/LarkKAFKMS'
  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'zhaojiachen.hydra@bytedance.com, hanlianzhen@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = "5.1"

  # 以下2个字段不要修改。EEScaffold会自动修改so urce字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = {:git => 'git@code.byted.org:lark/ios-infra.git', :tag => s.version.to_s}

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

  s.prepare_command = <<-CMD
    ./pull_ka_sdk.sh
  CMD

  # for default_subspecs
  s.subspec 'Core' do |sub|
    sub.source_files = 'src/Core/*.{h,cc}'
  end

  s.subspec 'WST' do |sub|
    sub.vendored_frameworks = 'frameworks/WST/*.xcframework'
  end

  s.subspec 'TW' do |sub|
    sub.vendored_frameworks = 'frameworks/TW/*.{framework,xcframework}'
  end

  s.default_subspecs = 'Core'
end
