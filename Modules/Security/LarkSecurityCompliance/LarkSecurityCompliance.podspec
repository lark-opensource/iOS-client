# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkSecurityCompliance.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|

  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSecurityCompliance'
  s.version = '5.31.0.5482055'
  s.summary          = 'Lark 安全合规业务组件库'
  s.description      = 'Lark 安全合规业务组件库'
  s.homepage         = 'https://code.byted.org/lark/ios_security_and_compliance'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'chengqingchun@bytedance.com'
  }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'

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
    "git_url": 'https://code.byted.org/lark/ios_security_and_compliance'
  }
  
  s.subspec 'Default' do |ss|
    # s.public_header_files = 'Pod/Classes/**/*.h'
    ss.source_files = 'src/**/*.{swift,h,m}'
    ss.exclude_files = ['src/Tests/**/*', 'src/Debug/**/*']
    ss.resource_bundles = {
        'LarkSecurityCompliance' => ['resources/*.lproj/*', 'resources/*'],
        'LarkSecurityComplianceAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
    }
    
    ss.dependency 'LarkLocalizations'
     
    ss.dependency 'BootManager'
    ss.dependency 'LarkPreload'
    ss.dependency 'LarkFeatureGating'
    ss.dependency 'RxSwift'
    ss.dependency 'RxCocoa'
    ss.dependency 'LarkContainer'
    ss.dependency 'LarkAppLinkSDK'
    ss.dependency 'LarkUIKit'
    ss.dependency 'SnapKit'
    ss.dependency 'Swinject'
    ss.dependency 'LarkAssembler'
    ss.dependency 'LarkAccountInterface'
    ss.dependency 'LarkRustClient'
    ss.dependency 'RustPB'
    ss.dependency 'SwiftyJSON'
    ss.dependency 'WebBrowser'
    ss.dependency 'LKCommonsTracker'
    ss.dependency 'LarkSecurityAudit'
    ss.dependency 'LarkEMM'
    ss.dependency 'LarkWaterMark'
    ss.dependency 'LarkSecurityAudit'
    ss.dependency 'TTReachability'
    ss.dependency 'LarkStorage'
    
    ss.dependency 'UniverseDesignButton'
    ss.dependency 'UniverseDesignColor'
    ss.dependency 'UniverseDesignEmpty'
    ss.dependency 'UniverseDesignIcon'
    ss.dependency 'UniverseDesignActionPanel'
    ss.dependency 'UniverseDesignToast'

    ss.dependency 'LarkSecurityComplianceInfra'
    ss.dependency 'LarkSecurityComplianceInterface'
    ss.dependency 'LarkSnCService'
    ss.dependency 'LarkEMM'
    ss.dependency 'LarkSensitivityControl/API/AudioRecord'
    ss.dependency 'LarkSensitivityControl/API/Camera'
    ss.dependency 'CryptoSwift'
    ss.dependency 'LarkPolicyEngine'
    ss.dependency 'LarkPrivacyMonitor'

    ss.dependency 'LarkOpenSetting'
    ss.dependency 'LarkSettingUI'
  end
  
  s.default_subspec = 'Default'
  
  s.test_spec 'Tests' do |ss|
    ss.source_files = 'src/Tests/**/*.{h,m,mm,swift}'
    ss.xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym' # 从dsym里面解析case-文件的映射关系
    }
    ss.scheme = {
      :code_coverage => true, # 开启覆盖率
      :environment_variables => {'UNIT_TEST' => '1'}, # 单测启动环境变量
    }
    ss.dependency 'LarkSecurityCompliance/Default'
  end

  s.subspec 'Debug' do |ss| 
    ss.source_files = 'src/Debug/**/*'
    ss.dependency 'LarkEMM/Debug'
    ss.xcconfig = {
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => 'SECURITY_DEBUG',
      "GCC_PREPROCESSOR_DEFINITIONS" => 'SECURITY_DEBUG=1'
    }
    ss.dependency 'LarkSecurityCompliance/Default'
  end

end
