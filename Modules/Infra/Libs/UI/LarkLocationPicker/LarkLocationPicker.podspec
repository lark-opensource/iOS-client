# coding: utf-8
#
# Be sure to run `pod lib lint LarkLocationPicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = "LarkLocationPicker"
  s.version = '5.31.0.5465592'
  s.summary          = "Required. 一句话描述该Pod功能"
  s.description      = "Required. 描述该Pod的功能组成等信息"
  s.homepage = 'ssh://zhuchao.03@git.byted.org:29418/ee/ios-infra'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors           = {
    "姚启灏": "yaoqihao@bytedance.com"
  }

  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.resource_bundles = {
      'LarkLocationPicker' => ['resources/*'] ,
      'LarkLocationPickerAuto' => 'auto_resources/*'
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { :git => 'generated_by_eesc.zip', :tag => s.version.to_s}

  # s.frameworks = 'UIKit', 'MapKit'

  # 国内的地图依赖配置
  s.subspec 'InternalDependency' do |cs|
    cs.dependency 'LarkLocationPicker/internal'
    cs.dependency 'LarkLocationPicker/common'
  end

  # 海外的地图依赖配置
  s.subspec 'OverSeaDependency' do |cs|
    cs.dependency 'LarkLocationPicker/oversea'
    cs.dependency 'LarkLocationPicker/common'
  end

  s.subspec 'internal' do |sub|
    sub.source_files = 'src/LocationPickerInternal/**/*.{swift,h,m}'
    sub.dependency 'AMapSearch-NO-IDFA'
  end

  s.subspec 'oversea' do |sub|
    sub.source_files = 'src/LocationPickerOverSea/**/*.{swift,h,m}'
  end

  s.subspec 'common' do |sub|
    sub.source_files = [
    'src/LocationPickerCommon/**/*.{swift,h,m}',
    'src/OpenLocation/**/*.{swift,h,m}',
    'src/ChooseLocation/**/*.{swift,h,m}',
    'src/configurations/**/*.{swift,h,m}'
    ]
    sub.dependency 'LarkLocalizations'
    sub.dependency "SnapKit"
    sub.dependency 'LarkUIKit'
    sub.dependency 'RxDataSources'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'Homeric'
    sub.dependency 'LKCommonsTracker'
    sub.dependency 'LarkTag'
    sub.dependency 'UniverseDesignIcon'
    sub.dependency 'UniverseDesignColor'
    sub.dependency 'UniverseDesignShadow'
    sub.dependency 'UniverseDesignToast'
    sub.dependency 'UniverseDesignActionPanel'
    sub.dependency 'UniverseDesignEmpty'
    sub.dependency 'LarkPrivacySetting'
    sub.dependency 'AppReciableSDK'
    sub.dependency 'LarkCoreLocation'
    sub.dependency 'LarkSensitivityControl/API/Location'
    sub.dependency 'LarkSensitivityControl/API/DeviceInfo'
  end

  s.default_subspecs = ['common']

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  #attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  #}
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": "Required."
  }
end
