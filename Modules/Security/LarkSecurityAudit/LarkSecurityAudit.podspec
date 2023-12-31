# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkSecurityAudit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSecurityAudit'
  s.version = '5.31.0.5463996'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'email'
  }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.1'

  # s.public_header_files = 'Pod/Classes/**/*.h'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # 行为统计
  s.subspec 'Core' do |cs|
    cs.source_files = 'src/Core/**/*.{swift}'  
    cs.dependency 'SwiftProtobuf'
    cs.dependency 'SQLite.swift'
    cs.dependency 'LKCommonsLogging'
    cs.dependency 'ThreadSafeDataStructure'
    cs.dependency 'ReachabilitySwift'
    cs.dependency 'CryptoSwift'
    cs.dependency 'LarkNavigator'
    cs.dependency 'ByteDanceKit'
    cs.dependency 'LarkSecurityComplianceInfra'
  end

  # 权限管控
  s.subspec 'Authorization' do |cs|
    cs.source_files = 'src/Authorization/**/*.{swift}'
    cs.dependency 'LarkSecurityAudit/Core'
    cs.dependency 'RustSDK'
    cs.dependency 'ServerPB'
    cs.dependency 'LarkCache'
    cs.dependency 'LarkFeatureGating'
    cs.dependency 'LarkActionSheet'
    cs.dependency 'UniverseDesignToast'
    cs.dependency 'LarkSetting'
    cs.dependency 'LarkSecurityComplianceInfra'
  end


  # 初始化
  s.subspec 'Assembly' do |cs|
    cs.source_files = 'src/Assembly/**/*.{swift}'  
    cs.dependency 'Swinject'
    cs.dependency 'BootManager'
    cs.dependency 'LarkAccountInterface'
    cs.dependency 'LarkSetting'
    cs.dependency 'LarkAssembler'
  end
  
  s.test_spec 'Tests' do |ss|
    ss.source_files = 'src/Tests/**/*.{h,m,mm,swift}'
    ss.xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym' # 从dsym里面解析case-文件的映射关系
    }
    ss.scheme = {
      :code_coverage => true, # 开启覆盖率
      :environment_variables => {'UNIT_TEST' => '1'}, # 单测启动环境变量
    }
    ss.dependency 'OCMock' # 表达式引擎组件是 OC 库，需要增加 OCMock 依赖
  end
  
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
