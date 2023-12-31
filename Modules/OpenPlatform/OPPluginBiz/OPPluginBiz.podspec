# frozen_string_literal: true

#
# Be sure to run `pod lib lint OPPluginBiz.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'OPPluginBiz'
  s.version          = '1.0.0'
  s.summary          = '开放平台API业务复用层'
  s.description      = '开放平台API业务复用层'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "baojianjun": 'baojianjun.786@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files = 'src/**/*.{swift,h,m,mm}'
  # 需要资源时再解开注释
#  s.resource_bundles = {
#    'OPPluginBiz' => ['resources/*.lproj/*', 'resources/*'],
#    'OPPluginBizAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
#  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.frameworks = 'UIKit'
  # 飞书基建
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkContainer'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkBadge'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignColor'
  s.dependency 'EENavigator'
  s.dependency 'TTRoute', '0.2.33'

  # 开平基建
  s.dependency 'ECOInfra'
  s.dependency 'OPFoundation'
  s.dependency 'LarkOpenPluginManager'
  s.dependency 'LarkOpenAPIModel'

  # Interface
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkOPInterface'

  # 三方库
  s.dependency 'SSZipArchive'

  # deprecated
  s.dependency 'TTMicroApp'
  s.dependency 'EEMicroAppSDK' # FG兜底期间临时依赖, 依赖EERoute.shared().delegate


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
