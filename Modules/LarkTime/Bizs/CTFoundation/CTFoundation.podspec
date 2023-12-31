# frozen_string_literal: true

# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
# 

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'CTFoundation'
  s.version = '5.31.0.5453726'
  s.summary          = 'CTFoundation'
  s.homepage         = 'https://code.byted.org/lark/calendar-ios'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "zhangwei": 'zhangwei.wy@bytedance.com'
  }
  s.platform = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.3"

  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'CTFoundation' => ['resources/*'] ,
      'CTFoundationAuto' => 'auto_resources/*'
  }

  s.license          = 'MIT'
  s.source           = { git: 'git@code.byted.org:lark/calendar-ios.git', tag: s.version.to_s }

  s.dependency 'LarkLocalizations'
  s.dependency 'LarkExtensions'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkFoundation'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'LarkDatePickerView'
  s.dependency 'CalendarFoundation'

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
