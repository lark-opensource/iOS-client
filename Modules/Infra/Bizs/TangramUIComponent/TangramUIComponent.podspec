# frozen_string_literal: true

#
# Be sure to run `pod lib lint TangramUIComponent.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'TangramUIComponent'
  s.version = '5.31.0.5479096'
  s.summary          = 'UI TangramComponent'
  s.description      = 'UI TangramComponent'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-infra/tree/master/TangramUIComponent'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "yuanping": 'yuanping.0@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # 所有的资源文件包括： 图片、表情、I18n的Strings
  s.subspec 'Resources' do |cs|
    cs.source_files = 'src/configurations/**/*'
    cs.resource_bundles = {
        'TangramUIComponent' => ['resources/*.lproj/*', 'resources/*'],
        'TangramUIComponentAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
    }
    cs.dependency 'LarkResource'
    cs.dependency 'UniverseDesignIcon'
  end

  s.subspec 'Base' do |cs|
    cs.source_files = ['src/Source/Base/**/*.swift']
  end

  s.subspec 'Component' do |cs|
    cs.source_files = ['src/Source/Component/**/*.swift']
    cs.dependency 'LarkLocalizations'
    cs.dependency 'TangramComponent'
    cs.dependency 'RichLabel'
    cs.dependency 'UniverseDesignButton'
    cs.dependency 'UniverseDesignCardHeader'
    cs.dependency 'LarkInteraction'
    cs.dependency 'TangramUIComponent/Base'
    cs.dependency 'TangramUIComponent/UI'
  end

  s.subspec 'UI' do |cs|
    cs.source_files = ['src/Source/UI/**/*.swift']
    cs.dependency 'LarkInteraction'
    cs.dependency 'LarkLocalizations'
    cs.dependency 'LarkTag'
    cs.dependency 'LarkExtensions'
    cs.dependency 'UniverseDesignColor'
    cs.dependency 'UniverseDesignFont'
    cs.dependency 'UniverseDesignButton'
    cs.dependency 'UniverseDesignLoading'
    cs.dependency 'RichLabel'
    cs.dependency 'LarkBizAvatar'
    cs.dependency 'TangramUIComponent/Resources'
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
