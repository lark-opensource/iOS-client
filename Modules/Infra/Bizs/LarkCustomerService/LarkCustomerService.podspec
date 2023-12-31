# coding: utf-8
#
# Be sure to run `pod lib lint LarkCustomerService.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = "LarkCustomerService"
  s.version          = "0.23.1-scene.2"
  s.summary          = "LarkCustomerService EE iOS SDK组件"

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/LarkCustomerService'


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "maozhenning@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.source_files = 'src/**/*.{swift}'
  # s.resource_bundles = {
  #     'LarkCustomerService' => ['resources/*'] ,
  #     'LarkCustomerServiceAuto' => 'auto_resources/*'
  # }
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'EENavigator'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkUIKit'
  s.dependency 'RustPB'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkContainer'
  s.dependency 'LarkSetting'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkMessageBase'
  s.dependency 'LarkModel'
  s.dependency 'ThreadSafeDataStructure'

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
