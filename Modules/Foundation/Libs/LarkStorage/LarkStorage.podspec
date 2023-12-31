# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkStorage.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

# 引入if_pod语法扩展
eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkStorage'
  s.version          = '5.31.0.5481213'
  s.summary          = 'Lark 统一存储组件'
  s.description      = 'Lark 统一存储组件，提供：KeyValue 存储、文件存储'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "zhangwei": 'zhangwei.wy@bytedance.com'
  }

  s.swift_version = '5.0'

  s.subspec 'Base' do |ss|
    ss.source_files = 'src/Base/**/*.{h,m,swift}'

    ss.dependency 'LarkStorageCore/Base'
    ss.dependency 'LKLoadable'
  end

  s.subspec 'KeyValue' do |ss|
    ss.source_files = 'src/KeyValue/**/*.{swift}'

    ss.dependency 'LarkStorage/Base'
    ss.dependency 'LarkStorageCore/KeyValue'
    ss.dependency 'MMKV'
  end

  s.subspec 'Sandbox' do |ss|
    ss.source_files = 'src/Sandbox/**/*.{swift}'

    ss.dependency 'LarkStorage/Base'
    ss.dependency 'LarkStorageCore/Sandbox'
  end

  s.subspec 'Lark' do |ss|
    ss.source_files = 'src/Lark/**/*.{swift}'
    ss.dependency 'LarkContainer'
    ss.dependency 'LarkStorage/KeyValue'
    ss.dependency 'LarkStorage/Sandbox'
  end

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

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
