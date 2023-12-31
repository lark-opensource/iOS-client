Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkIMMention'
  s.version = '5.31.0.5456899'
  s.summary          = 'IM Mention组件'
  s.description      = 'IM Mention组件'
  s.homepage         = 'https://code.byted.org/lark/ios-infra'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "jiangxiangrui": 'jiangxiangrui@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.subspec 'Base' do |ss|
    ss.source_files = 'src/{Model,configurations}/**/*.{swift,h,m}'
    ss.resource_bundles = {
      'LarkIMMention' => ['resources/*.lproj/*', 'resources/*'],
      'LarkIMMentionAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
    }
    ss.dependency 'RustPB'
  end
  
  s.subspec 'Main' do |ss|
    ss.source_files = 'src/Main/**/*.{swift,h,m}'
    ss.dependency 'UniverseDesignToast'
    ss.dependency 'LarkFocus'
    ss.dependency 'LKCommonsLogging'
    ss.dependency 'LarkBizAvatar' #
  end
  
  s.subspec 'Service' do |ss|
    ss.source_files = 'src/Service/**/*.{swift,h,m}'
    ss.dependency 'LarkSearchCore'
    ss.dependency 'LarkExtensions'
  end
  
  s.subspec 'Assembly' do |ss|
    ss.source_files = 'src/Assembly/**/*.{swift,h,m}'
    ss.dependency 'LarkAssembler'
    ss.dependency 'LarkDebugExtensionPoint'
  end
  
  s.subspec 'Core' do |ss|
    ss.source_files = 'src/Core/**/*.{swift,h,m}'
    ss.dependency 'UniverseDesignShadow'
    ss.dependency 'LarkIMMention/Base'
    ss.dependency 'LarkIMMention/Util'
  end
  
  s.subspec 'Util' do |ss|
    ss.source_files = 'src/Util/**/*.{swift,h,m}'
    ss.dependency 'LarkIMMention/Base'
  end
  
  s.subspec 'View' do |ss|
    ss.source_files = 'src/View/**/*.{swift,h,m}'
    ss.dependency 'LarkUIKit/Checkbox'
    ss.dependency 'LarkUIKit/Resources'
    ss.dependency 'LarkUIKit/Common'
    ss.dependency 'LarkUIKit/LoadMore'
    ss.dependency 'LarkUIKit/TextField'
    ss.dependency 'UniverseDesignLoading'
    ss.dependency 'UniverseDesignEmpty'
    ss.dependency 'UniverseDesignShadow'
    ss.dependency 'UniverseDesignTabs'
    ss.dependency 'LarkTag'
    ss.dependency 'LarkBizTag'
    ss.dependency 'LarkBizTag/PB'
    ss.dependency 'LarkIMMention/Core'
  end
  
  s.subspec 'Debug' do |ss|
    ss.source_files = 'src/Debug/**/*.{swift,h,m}'
  end
  
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

#  s.default_subspec = 'Resources'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'SnapKit'
  s.dependency 'LarkLocalizations'

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'git@code.byted.org:lark/ios-infra.git'
  }
end
