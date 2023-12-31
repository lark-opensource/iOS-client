# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkSnsShare.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSnsShare'
  s.version = '5.30.0.5410491'
  s.summary          = 'Lark基础社交分享库'
  s.description      = 'Lark基础社交分享库，并封装了UI视图以及应对封禁等处理逻辑'
  s.homepage         = 'https://git.byted.org/a/ee/ee-infra'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "shizhengyu": 'shizhengyu@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }
  s.dependency 'LarkAssembler'
  
  # 国内版的sns依赖配置
  s.subspec 'InternalSnsShareDependency' do |cs|
    cs.dependency 'LarkSnsShare/Interface'
    cs.dependency 'LarkSnsShare/Base'
    cs.dependency 'LarkSnsShare/ExpansionAbility'
    cs.dependency 'BDUGShare/BDUGShareBasic/BDUGUtil'
    cs.dependency 'BDUGShare/BDUGShareBasic/BDUGWeChatShare'
    cs.dependency 'BDUGShare/BDUGShareBasic/BDUGQQShare'
    cs.dependency 'BDUGShare/BDUGShareBasic/BDUGWeiboShare'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkSnsShare_InternalSnsShareDependency' }
  end

  # 国际版的sns依赖配置
  s.subspec 'InternationalSnsShareDependency' do |cs|
    cs.dependency 'LarkSnsShare/Interface'
    cs.dependency 'LarkSnsShare/Base'
    cs.dependency 'LarkSnsShare/ExpansionAbility'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkSnsShare_InternationalSnsShareDependency' }
  end

  s.subspec 'Interface' do |sub|
    sub.source_files = 'src/Source/Interface/**/*.{swift,h,m}'
    sub.dependency 'RxSwift'
  end

  s.subspec 'Base' do |sub|
    sub.frameworks = 'WebKit'
    sub.resource_bundles = {
        'LarkSnsShare' => ['resources/*'],
        'LarkSnsShareAuto' => ['auto_resources/*']
    }
    sub.source_files = ['src/Source/Base/**/*.{swift,h,m}', 'src/configurations/**/*.{swift,h,m}']
    sub.dependency 'LarkSnsShare/Interface'
    sub.dependency 'LarkLocalizations'
    sub.dependency 'RxSwift'
    sub.dependency 'RxCocoa'
    sub.dependency 'LarkFeatureGating'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'SnapKit'
    sub.dependency 'LarkExtensions'
    sub.dependency 'AppContainer'
    sub.dependency 'EENavigator'
    sub.dependency 'LarkUIKit'
    sub.dependency 'LarkFoundation'
    sub.dependency 'LKLoadable'
    sub.dependency 'UniverseDesignColor'
    sub.dependency 'UniverseDesignIcon'
    sub.dependency 'UniverseDesignLoading'
    sub.dependency 'UniverseDesignShadow'
    sub.dependency 'FigmaKit'
    sub.dependency 'LarkAppResources'
  end

  s.subspec 'ExpansionAbility' do |sub|
    sub.source_files = ['src/Source/ExpansionAbility/**/*.{swift,h,m}']
    sub.dependency 'LarkSnsShare/Interface'
    sub.dependency 'LarkSnsShare/Base'
    sub.dependency 'LarkReleaseConfig'
    sub.dependency 'LarkShareToken'
    sub.dependency 'Kingfisher'
    sub.dependency 'RustPB'
    sub.dependency 'LarkRustClient'
    sub.dependency 'LarkAccountInterface'
    sub.dependency 'LKCommonsTracker'
    sub.dependency 'AsyncComponent'
    sub.dependency 'UniverseDesignPopover'
    sub.dependency 'UniverseDesignToast'
    sub.dependency 'LarkEMM'
    sub.dependency 'LarkSensitivityControl/Core'
  end

  s.default_subspecs = ['Interface', 'Base', 'ExpansionAbility']

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'https://git.byted.org/a/ee/ee-infra'
  }
end
