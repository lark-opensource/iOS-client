# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkVideoDirector.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkVideoDirector'
  s.version = '5.30.0.5410491'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'email'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/*.{h,m,swift}', 'src/configurations/*.{h,m,swift}'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  s.default_subspecs = 'Lark','CameraKit'
  s.public_header_files = 'src/*.h'

  s.dependency 'UniverseDesignToast'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignActionPanel'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkContainer'
  s.dependency 'LarkAppLog'
  s.dependency 'LarkMedia'

  s.resource_bundles = {
      'LarkVideoDirector' => ['resources/*.lproj/*', 'resources/*'],
      'LarkVideoDirectorAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }

  s.subspec 'Lark' do |ss|
    ss.source_files = 'src/Lark/*.swift'
    ss.dependency 'AppContainer'
    ss.dependency 'BootManager'
    ss.dependency 'LarkAssembler'
    ss.dependency 'LarkCache'
    ss.dependency 'LarkStorage/Lark'
    ss.dependency 'LarkStorage/Sandbox'
    ss.dependency 'LarkVideoDirector/CameraKit' # 没有实际依赖关系,只是默认一起引入
    ss.dependency 'LKCommonsLogging'
    ss.dependency 'RunloopTools'
    ss.dependency 'Swinject'

    ss.subspec 'VideoEngine' do |sss|
      sss.source_files = 'src/Lark/VideoEngine/*.swift'
      sss.dependency 'BDABTestSDK'
      sss.dependency 'LarkAccountInterface'
      sss.dependency 'LarkAppLog'
      sss.dependency 'LarkContainer'
      sss.dependency 'LarkFeatureGating'
      sss.dependency 'LarkFoundation'
      sss.dependency 'LarkKAFeatureSwitch'
      sss.dependency 'LarkReleaseConfig'
      sss.dependency 'LarkSetting'
      sss.dependency 'LarkTracker'
      sss.dependency 'LKCommonsTracker'
      sss.dependency 'TTVideoEngine'
      sss.dependency 'RangersAppLog/Core'
    end

    ss.subspec 'VideoEditor' do |sss|
      sss.source_files = 'src/Lark/VideoEditor/*.{h,m,swift}'
      sss.dependency 'BDAlogProtocol'
      sss.dependency 'Heimdallr'
      sss.dependency 'LarkAccountInterface'
      sss.dependency 'LarkContainer'
      sss.dependency 'LarkEnv'
      sss.dependency 'LarkFileKit'
      sss.dependency 'LarkFoundation'
      sss.dependency 'LarkReleaseConfig'
      sss.dependency 'LarkSetting'
      sss.dependency 'LKCommonsTracker'
      sss.dependency 'OfflineResourceManager'
      sss.dependency 'ThreadSafeDataStructure'
      sss.dependency 'TTVideoEditor'
      sss.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => [
        'ENABLE_SCENE_DETECT=1',
        'ENABLE_LUMA_DETECT=1'
      ]}
    end
  end

  s.subspec 'CameraKit' do |ss|
    ss.source_files = 'src/CameraKit/**/*.{swift,h}'
    ss.public_header_files = 'src/CameraKit/**/*.h'
    ss.dependency 'LarkSensitivityControl/API/Camera'
    ss.dependency 'LarkSensitivityControl/API/AudioRecord'
    ss.dependency 'LarkSensitivityControl/API/Album'
    ss.dependency 'LarkStorage/Sandbox'
    ss.dependency 'LarkCamera'
    ss.dependency 'LarkImageEditor/Interface'
    ss.dependency 'LarkContainer'
    ss.dependency 'LarkUIKit/Utils'
    ss.dependency 'LarkSceneManager'
    ss.dependency 'LarkMonitor'
    ss.dependency 'UniverseDesignDialog'
  end

  s.subspec 'CKNLE' do |ss|
    ss.public_header_files = 'src/CKNLE/Core/*.h'
    ss.private_header_files = 'src/CKNLE/{Category,Component,Container,Record,Service}/**/*.h'
    ss.source_files = 'src/CKNLE/**/*.{h,m,mm,c,swift}'
    ss.dependency 'CameraClient'
    ss.dependency 'CreativeKit'
    ss.dependency 'CreationKitInfra'
    ss.dependency 'CreationKitArch'
    ss.dependency 'CreationKitBeauty'
    ss.dependency 'CameraClientModel'
    ss.dependency 'CreationKitComponents'
    ss.dependency 'CreativeAlbumKit'
    ss.dependency 'NLEEditor/Adapter'
    ss.dependency 'OfflineResourceManager'
    ss.dependency 'LarkSensitivityControl/API/DeviceInfo'
    ss.pod_target_xcconfig = {
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'VideoDirectorIncludesCKNLE',
      'GCC_PREPROCESSOR_DEFINITIONS': [
        'ENABLE_LITEEDITOR=1',
        '__IOS__=1'
      ],
    }
  end

  s.subspec 'KA' do |ss|
    ss.source_files = 'src/KA/**/*.{h,m,mm,c,swift}'
    ss.resource_bundles = {
        'LarkVideoDirectorKA' => ['src/KA/*'],
    }
    ss.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'VideoDirectorKAResource' }
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
