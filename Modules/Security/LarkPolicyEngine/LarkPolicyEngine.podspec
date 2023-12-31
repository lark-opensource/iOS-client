# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkPolicyEngine.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkPolicyEngine'
  s.version          = '0.0.1'
  s.summary          = 'A policy engine SDK for SnC Infra.'
  s.description      = '飞书业务中台的安全合规策略引擎 SDK。'
  s.homepage         = 'https://code.byted.org/lark/snc-infra/tree/master/LarkPolicyEngine'
  s.authors          = { "Hao Wang": 'wanghao.ios@bytedance.com' }
  
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }
  
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files = 'src/PolicyEngine/**/*.{swift}'

  s.test_spec 'Tests' do |ss|
    ss.source_files = 'src/Tests/**/*.{swift}'
    ss.xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym' # 从dsym里面解析case-文件的映射关系
    }
    ss.scheme = {
      :code_coverage => true, #开启覆盖率
      :environment_variables => {'UNIT_TEST' => '1'}, #单测启动环境变量
    }
  end

  s.dependency 'LarkSnCService/Core'
  s.dependency 'LarkExpressionEngine'
  s.dependency 'ReachabilitySwift'
  s.dependency 'ByteDanceKit'
  s.dependency 'SwiftyJSON'
  s.dependency 'LarkRustClient'
  s.dependency 'RustPB'
  s.dependency 'ThreadSafeDataStructure'

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
