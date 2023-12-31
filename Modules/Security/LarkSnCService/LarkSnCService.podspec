# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkSnCService.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSnCService'
  s.version          = '0.0.1'
  s.summary          = 'A collection of services for SnC infra SDK.'
  s.description      = '飞书业务中台安全合规 SDK 外部注入能力服务集合'
  s.homepage         = 'https://code.byted.org/lark/snc-infra/tree/master/LarkSnCService'
  s.authors          = { "Hao Wang": 'wanghao.ios@bytedance.com' }
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |ss|
    ss.source_files = 'src/Core/**/*.{swift}'
  end
  
  s.subspec 'Extensions' do |ss|
    ss.subspec 'Bundle' do |bundle|
      bundle.source_files = 'src/Extensions/Bundle/*.{swift}'
      bundle.dependency 'SSZipArchive'
    end
    
    ss.subspec 'ConvenientTools' do |tools|
      tools.source_files = 'src/Extensions/ConvenientTools/*.{swift}'
    end
  end
  
  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'https://code.byted.org/lark/snc-infra'
  }
end
