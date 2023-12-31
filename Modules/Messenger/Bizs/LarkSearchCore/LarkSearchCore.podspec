# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkSearchCore.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSearchCore'
  s.version = '5.32.0.5486858'
  s.summary          = '包含LarkSearch对外提供的核心功能，会尽量减少依赖，可被外部组件'
  s.description      = '包含LarkSearch对外提供的核心功能，会尽量减少依赖，可被外部组件'
  s.homepage         = 'git@code.byted.org:lark/Lark-Messenger.git'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
      "wangxiaohua": 'wangxiaohua@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'

  # s.public_header_files = 'Pod/Classes/**/*.h'


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'
  
  s.subspec 'Main' do |ss|
    ss.source_files = 'src/{Config,Search}/**/*.{swift}'
    ss.dependency 'LarkSearchCore/Base'
    ss.dependency 'EEAtomic'
    ss.dependency 'Homeric'
    ss.dependency 'LKCommonsLogging'
    ss.dependency 'LKCommonsTracker'
    ss.dependency 'LKMetric'
    ss.dependency 'LarkAccountInterface'
    ss.dependency 'LarkBizAvatar'
    ss.dependency 'LarkContainer'
    ss.dependency 'LarkCore'
    ss.dependency 'LarkFeatureGating'
    ss.dependency 'LarkListItem'
    ss.dependency 'LarkLocalizations'
    ss.dependency 'LarkMessengerInterface'
    ss.dependency 'LarkModel'
    ss.dependency 'LarkRustClient'
    ss.dependency 'LarkSDKInterface'
    ss.dependency 'LarkFocusInterface'
    ss.dependency 'LarkSearchFilter' # TODO: 之后可能需要近一步拆分依赖
    ss.dependency 'LarkUIKit'
    ss.dependency 'ReachabilitySwift'
    ss.dependency 'RustPB'
    ss.dependency 'RxCocoa'
    ss.dependency 'RxSwift'
    ss.dependency 'SnapKit'
    ss.dependency 'LarkLocationPicker'
    ss.dependency 'Lynx'
    ss.dependency 'XElement/Swiper'
    ss.dependency 'XElement/Input'
    ss.dependency 'XElement/Picker'
    ss.dependency 'XElement/Text'
    ss.dependency 'XElement/ScrollView'
    ss.dependency 'ByteWebImage'
    ss.dependency 'OfflineResourceManager'
    ss.dependency 'LarkGuide'
    ss.dependency 'LarkAssembler'
    ss.dependency 'LarkEnv'
    ss.dependency 'LarkOpenFeed'
    ss.dependency 'LarkEMM'
    ss.dependency 'LarkBizTag'
    ss.dependency 'LarkSensitivityControl/API/Pasteboard'
    ss.dependency 'LarkSensitivityControl/API/Album'
    ss.dependency 'LarkLocalizations'
    ss.dependency 'RichLabel'
    ss.dependency 'LarkTag'
    ss.dependency 'RxSwift'
    ss.dependency 'RxCocoa'
    ss.dependency 'SnapKit'
    ss.dependency 'LarkFocusInterface'

    ss.dependency 'LarkCore'
    ss.dependency 'LarkModel'
    ss.dependency 'LarkAccountInterface'
    ss.dependency 'LarkMessengerInterface'
  end
  
  s.subspec 'Picker' do |ss|
    ss.source_files = 'src/Picker/{Main,Service}/**/*.{swift,h,m}', 'src/Picker/*.swift'
    ss.dependency 'LarkSearchCore/View'
  end
  
  s.subspec 'View' do |ss|
    ss.source_files = 'src/Picker/{View,Model}/**/*.{swift,h,m}'
    ss.dependency 'LarkSearchCore/Base'
    ss.dependency 'LarkUIKit/Checkbox'
    ss.dependency 'LarkUIKit/Common'
    ss.dependency 'LarkListItem/Components'
    ss.dependency 'UniverseDesignLoading'
    ss.dependency 'UniverseDesignEmpty'
    ss.dependency 'UniverseDesignShadow'
    ss.dependency 'UniverseDesignTabs'
    ss.dependency 'UniverseDesignButton'
    ss.dependency 'UniverseDesignColor'
  end

  s.subspec 'Services' do |ss|
    ss.source_files = 'src/Picker/Services/**/*.{swift,h,m}'
    ss.dependency 'LarkSearchCore/Utils'
  end
  
  s.subspec 'Utils' do |ss|
    ss.source_files = 'src/Picker/Utils/**/*.{swift,h,m}'
    ss.dependency 'LarkModel/Base'
    ss.dependency 'LarkContactComponent/Utils'
    ss.dependency 'Homeric'
  end
  
  s.subspec 'Base' do |ss|
    ss.source_files = 'src/Picker/{Model,Config,Core,ServiceInterface}/**/*.{swift,h,m}','src/configurations/*.{swift,h,m}'
    ss.resource_bundles = {
        'LarkSearchCore' => ['resources/*.lproj/*', 'resources/*'],
        'LarkSearchCoreAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
    }
    ss.dependency 'RustPB'
    ss.dependency 'LarkLocalizations'
    ss.dependency 'LarkModel/Base'
  end

  s.test_spec 'Tests' do |test_spec|
      test_spec.test_type = :unit
      test_spec.source_files = 'app/test/src/**/*.{swift,h,m,mm,cpp}'
      test_spec.pod_target_xcconfig = {
        'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
      }
      test_spec.scheme = {
        :code_coverage => true
      }

      # 给 test_spec 添加第三方依赖，比如 “OCMock”
      # test_spec.dependency 'xxxx'

      # 给 test_spec 添加资源文件
      # test_spec 本质上也是一个 subspec，其语法元素与其他 subspec 是一样的
      #  ModuleUnitTest：请根据你的组件名自定义名字
      #  'test_resources/*'：自定义资源文件路径
      # test_spec.resource_bundles = {
      #   'ModuleUnitTest' => ['test_resources/*']
      # }
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
