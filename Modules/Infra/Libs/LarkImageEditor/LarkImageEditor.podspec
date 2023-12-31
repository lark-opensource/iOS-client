# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkImageEditor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkImageEditor'
  s.version = '5.31.0.5463996'
  s.summary          = 'Lark iOS  图片编辑组件'
  s.description      = 'Lark iOS  图片编辑组件'
  s.homepage         = 'Lark iOS  图片编辑组件'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'email'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.subspec 'Common' do |sub|
      sub.source_files = 'src/configurations/**/*.{swift,h,m}', 'src/Common/**/*.{swift,h,m}'
      sub.dependency 'LarkLocalizations'
      sub.dependency 'UniverseDesignIcon'
      sub.resource_bundles = {
          'LarkImageEditor' => ['resources/*.lproj/*', 'resources/*'],
          'LarkImageEditorAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
      }
  end

  # 仅有Mock实现
  s.subspec 'Interface' do |sub|
    sub.source_files = 'src/Interface/**/*.{swift,h,m}'
    sub.dependency 'RxSwift'
    sub.dependency 'LarkSetting/Core'
  end

  # V1
  s.subspec 'V1' do |sub|
    sub.source_files = 'src/ImageEditV1/**/*.{swift,h,m}'
    sub.dependency 'LarkImageEditor/Interface'
    sub.dependency 'LarkImageEditor/Common'
    sub.dependency 'SnapKit'
    sub.dependency 'RxSwift'
    sub.dependency 'RxCocoa'
    sub.dependency 'LarkExtensions'
    sub.dependency 'LarkUIKit/Utils'
    sub.dependency 'LarkUIKit/Base'
    sub.dependency 'LarkUIKit/Others'
    sub.dependency 'LarkUIKit/LoadPlaceholder'
    sub.dependency 'LarkUIKit/TextField'
    sub.dependency 'Swinject'
    sub.dependency 'LarkGuide'
    sub.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkImageEditor_V1' }
  end

  # V2
  s.subspec 'V2' do |sub|
    sub.source_files = 'src/ImageEditV2/**/*.{swift,h,m}'
    sub.dependency 'LarkImageEditor/Interface'
    sub.dependency 'LarkImageEditor/Common'
    sub.dependency 'LarkImageEditor/CropV2'
    sub.dependency 'TTVideoEditor/LarkMode'
    sub.dependency 'TTVideoEditor/TTVEImage'
    sub.dependency 'SSZipArchive'
    sub.dependency 'LarkBlur'
    sub.dependency 'SnapKit'
    sub.dependency 'RxSwift'
    sub.dependency 'RxCocoa'
    sub.dependency 'LarkExtensions'
    sub.dependency 'LarkUIKit/Utils'
    sub.dependency 'LarkUIKit/Base'
    sub.dependency 'LarkUIKit/Others'
    sub.dependency 'LarkUIKit/LoadPlaceholder'
    sub.dependency 'LarkUIKit/TextField'
    sub.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkImageEditor_V2' }
  end

  # Image Cropper V2
  s.subspec 'CropV2' do |sub|
    sub.source_files = 'src/ImageCropV2/*.{swift,h,m}'
    sub.dependency 'LarkImageEditor/Interface'
    sub.dependency 'LarkImageEditor/Common'
    sub.dependency 'LarkUIKit/Utils'
    sub.dependency 'LarkUIKit/Base'
    sub.dependency 'LarkUIKit/Others'
    sub.dependency 'LarkUIKit/LoadPlaceholder'
    sub.dependency 'LarkUIKit/TextField'
    sub.dependency 'FigmaKit'
    sub.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkImageCropper_V2' }
  end

  s.default_subspecs = ['Interface']

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
