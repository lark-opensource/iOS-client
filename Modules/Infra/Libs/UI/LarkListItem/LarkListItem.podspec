# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkListItem.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkListItem'
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

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.subspec 'Resources' do |ss|
    ss.source_files = 'src/configurations/*.{swift,h,m}'
    ss.resource_bundles = {
        'LarkListItem' => ['resources/*'] ,
        'LarkListItemAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
    }
#    ss.dependency 'RustPB'
    ss.dependency 'LarkLocalizations'
  end
  
  s.subspec 'Main' do |ss|
    ss.source_files = 'src/**/*.{swift}'
    ss.exclude_files = 'src/{Services,Utils,configurations}/**/*.{swift}'
    ss.dependency 'LarkListItem/Cell'
    ss.dependency 'SnapKit'
    ss.dependency 'RxSwift'
    ss.dependency 'RxCocoa'
    ss.dependency 'LarkUIKit'
    ss.dependency 'UniverseDesignColor'
    ss.dependency 'UniverseDesignIcon'
    ss.dependency 'LarkFoundation'
    ss.dependency 'LarkExtensions'
    ss.dependency 'LarkDocsIcon'
    ss.dependency 'LarkBizAvatar'
    ss.dependency 'LarkTag'
    ss.dependency 'LarkBizTag'
  end
  
  s.subspec 'Components' do |ss|
    ss.source_files = 'src/Components/**/*.{swift}'
#    ss.dependency 'LarkBizAvatar'
    ss.dependency 'LarkListItem/Core'
    ss.dependency 'LarkListItem/Resources'
    ss.dependency 'SnapKit'
    ss.dependency 'RxSwift'
    ss.dependency 'RxCocoa'
    ss.dependency 'UniverseDesignColor'
    ss.dependency 'UniverseDesignIcon'
    ss.dependency 'RichLabel'
    ss.dependency 'LarkUIKit/Checkbox'
    ss.dependency 'LarkUIKit/Common'
    ss.dependency 'LarkModel/Base'
    ss.dependency 'LarkContactComponent/Utils'
    ss.dependency 'LarkRichTextCore/Base'
  end

  s.subspec 'Core' do |ss|
    ss.source_files = 'src/{Core,Services}/**/*.{swift}'
    ss.dependency 'LarkListItem/Resources'
    ss.dependency 'LarkListItem/Utils'
    ss.dependency 'SnapKit'
    ss.dependency 'RxSwift'
    ss.dependency 'RxCocoa'
    ss.dependency 'UniverseDesignColor'
    ss.dependency 'UniverseDesignIcon'
    ss.dependency 'RichLabel'
    ss.dependency 'LarkUIKit/Checkbox'
    ss.dependency 'LarkUIKit/Common'
    ss.dependency 'LarkModel/Base'
    ss.dependency 'LarkContactComponent/Utils'
    ss.dependency 'LarkRichTextCore/Base'
  end

  s.subspec 'Cell' do |ss|
    ss.source_files = 'src/Cell/*.{swift}'
    ss.dependency 'LarkListItem/Components'
  end

  s.subspec 'Utils' do |ss|
    ss.source_files = 'src/Utils/**/*.{swift}'
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
