# frozen_string_literal: true

#
# Be sure to run `pod lib lint SKBitable.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name = 'SKBitable'
  s.version = '5.31.0.5341924'
  s.summary = 'Bitable多维表格'
  s.description = '多维表格/Bitable 的 native 实现，包含预览页的 menu 和卡片页的代码'
  s.homepage = 'https://code.byted.org/ee/spacekit-ios/tree/develop/Bizs/SKBitable'

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    'yinyuan.0': 'yinyuan.0@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.3'

  s.preserve_paths = ['Scripts', 'SKBitable.podspec']

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp,xib,c}'
  s.resource_bundles = {
    'SKBitable' => ['Resources/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'SKFoundation'
  s.dependency 'SKUIKit'
  s.dependency 'SKCommon/Core'
  s.dependency 'SKBrowser'
  s.dependency 'SKResource'
  s.dependency 'LarkCamera'
  s.dependency 'LarkImageEditor'
  s.dependency 'ByteWebImage'
  s.dependency 'RxDataSources'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignToast'
  s.dependency 'UniverseDesignProgressView'
  s.dependency 'UniverseDesignCheckBox'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'UniverseDesignInput'
  s.dependency 'UniverseDesignDatePicker'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'LarkLocationPicker'
  s.dependency 'LarkCoreLocation'
  s.dependency 'UniverseDesignMenu'
  s.dependency 'LarkEMM'
  s.dependency 'LarkOpenAPIModel'
  s.dependency 'LarkOpenPluginManager'
  s.dependency 'OPSDK'
  s.dependency 'LarkContainer'
  s.dependency 'LarkModel'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkSceneManager'
  s.dependency 'LarkQuickLaunchInterface'
  s.dependency 'LarkTraitCollection'
  s.dependency 'LarkTab'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkWebViewContainer'
  s.dependency 'WebBrowser'
  s.dependency 'OPFoundation'
  s.dependency 'ECOProbe'
  s.dependency 'UniverseDesignNotice'
  s.dependency 'SpaceInterface'
  s.dependency 'LarkSplitViewController'
  s.dependency 'LarkSensitivityControl/API/Album'
  s.dependency 'LarkAudioKit'
  s.dependency 'QRCode'
  s.dependency 'LarkUIKit'
  s.dependency 'Heimdallr'
  s.dependency 'LarkLynxKit'
  s.dependency 'LarkDocsIcon'

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'git@code.byted.org:ee/spacekit-ios.git'
  }

  # 单元测试
  s.test_spec 'Tests' do |test_spec|
    test_spec.test_type = :unit
    test_spec.source_files = 'tests/**/*.{swift,h,m,mm,cpp}'
    test_spec.resources = 'tests/Resources/*'
    test_spec.xcconfig = {
        'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
    }
    test_spec.scheme = {
        :code_coverage => true,
        :environment_variables => {'UNIT_TEST' => '1'},
        :launch_arguments => []
    }
    test_spec.dependency 'OHHTTPStubs/Swift'
    test_spec.dependency 'SwiftyJSON'
  end
end
