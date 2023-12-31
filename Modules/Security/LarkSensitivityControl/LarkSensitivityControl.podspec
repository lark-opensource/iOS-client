# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkSensitivityControl.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSensitivityControl'
  s.version          = '0.0.1'
  s.summary          = 'A sensitivity control SDK for SnC Infra.'
  s.description      = '飞书业务中台安全合规敏感 API 管控 SDK。'
  s.homepage         = 'https://code.byted.org/lark/snc-infra/tree/develop/LarkSensitivityControl'
  s.authors          = { "Hao Wang": 'wanghao.ios@bytedance.com' }
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
  s.default_subspec = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files = ['src/Sources/Core/**/**/*.{swift}']
    ss.resource_bundles = {
      'LarkSensitivityControl' => ['resources/*.lproj/*', 'resources/*']
    }
    ss.dependency 'LarkSnCService'
    ss.dependency 'ThreadSafeDataStructure'
    ss.dependency 'SSZipArchive'
  end

  s.subspec 'API' do |ss|
    ss.dependency 'LarkSensitivityControl/Core'

    ss.subspec 'Location' do |location|
      location.source_files = ['src/Sources/API/Location/**/*.{swift}']
    end

    ss.subspec 'Pasteboard' do |pasteboard|
      pasteboard.source_files = ['src/Sources/API/Pasteboard/**/*.{swift}']
    end

    ss.subspec 'DeviceInfo' do |deviceInfo|
      deviceInfo.source_files = ['src/Sources/API/DeviceInfo/**/*.{swift}']
    end

    ss.subspec 'AudioRecord' do |audioRecord|
      audioRecord.source_files = ['src/Sources/API/AudioRecord/**/*.{swift}']
    end

    ss.subspec 'Camera' do |camera|
      camera.source_files = ['src/Sources/API/Camera/**/*.{swift}']
    end

    ss.subspec 'Calendar' do |calendar|
      calendar.source_files = ['src/Sources/API/Calendar/**/*.{swift}']
    end

    ss.subspec 'Contacts' do |contacts|
      contacts.source_files = ['src/Sources/API/Contacts/**/*.{swift}']
    end

    ss.subspec 'Album' do |album|
      album.source_files = ['src/Sources/API/Album/**/*.{swift}']
    end

    ss.subspec 'RTC' do |rtc|
      rtc.source_files = ['src/Sources/API/RTC/**/*.{swift}']
    end

  end

  s.subspec 'Debug' do |ss|
    ss.source_files = ['src/Sources/Debug/**/*.{swift}']
  end
  
  s.subspec 'InHouse' do |ss|
    ss.source_files = ['src/Sources/InHouse/**/*.{swift}']
  end

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.source_files = ['src/Sources/**/**/*.{swift}']
  #s.resource_bundles = {
      #'LarkSensitivityControl' => ['resources/*.lproj/*', 'resources/*']
  #}

  s.test_spec 'Tests' do |ss|
    ss.source_files = 'src/Tests/**/*.{swift}'
    ss.resource_bundles = {
        'LarkSensitivityControlTest' => ['src/Tests/resourcestest/*']
    }
    ss.xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym' # 从dsym里面解析case-文件的映射关系
    }
    ss.scheme = {
      :code_coverage => true, #开启覆盖率
      :environment_variables => {'UNIT_TEST' => '1'}, #单测启动环境变量
    }
  end

  # s.dependency 'LarkLocalizations'
  # s.dependency 'LarkSnCService'

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'https://code.byted.org/lark/snc-infra'
  }

end
