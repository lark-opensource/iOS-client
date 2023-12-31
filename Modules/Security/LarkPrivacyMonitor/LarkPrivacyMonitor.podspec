# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkPrivacyMonitor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkPrivacyMonitor'
  s.version          = '0.0.1'
  s.summary          = 'A privacy monitor SDK for SnC Infra.'
  s.description      = '飞书业务中台安全合规敏感 API 精细化场景监控 SDK。'
  s.homepage         = 'https://code.byted.org/lark/SnC-Infra/tree/develop/LarkPrivacyMonitor'

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "huanzhengjie": 'huanzhengjie@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |ss|
    ss.source_files = ['src/Sources/Core/**/**/*.{swift,m,h}']
    ss.resource_bundles = {
      'LarkPrivacyMonitor' => ['resources/*.lproj/*', 'resources/*']
    }
    ss.dependency 'TSPrivacyKit/ModuleInterface'
    ss.dependency 'TSPrivacyKit/Pipelines/Location/CLLocationManagerLocation/Normal'
    ss.dependency 'TSPrivacyKit/Pipelines/Wifi/NEHotspotNetwork'
    ss.dependency 'TSPrivacyKit/Pipelines/Wifi/CaptiveNetwork'
    ss.dependency 'TSPrivacyKit/Pipelines/Network/CLGeocoder'
    ss.dependency 'TSPrivacyKit/Pipelines/LockID/LAContext'
    ss.dependency 'TSPrivacyKit/Pipelines/IP/ifaddrs'
    ss.dependency 'TSPrivacyKit/Pipelines/Motion/UIDeviceMotion'
    ss.dependency 'TSPrivacyKit/Pipelines/Motion/CMMotionManager'
    ss.dependency 'TSPrivacyKit/Pipelines/Motion/CLLocationManagerMotion'
    ss.dependency 'TSPrivacyKit/Pipelines/Contact/CNContactStore'
    ss.dependency 'TSPrivacyKit/Pipelines/CallCenter/CTCallCenter'
    ss.dependency 'TSPrivacyKit/Pipelines/Calendar'
    ss.dependency 'TSPrivacyKit/Pipelines/Album'
    ss.dependency 'TSPrivacyKit/Pipelines/Audio/AudioOutput'
    ss.dependency 'TSPrivacyKit/Pipelines/Audio/AVAudioSession'
    ss.dependency 'TSPrivacyKit/Pipelines/Audio/AVCaptureDeviceAudio'
    ss.dependency 'TSPrivacyKit/Pipelines/Audio/AudioQueue'
    ss.dependency 'TSPrivacyKit/Pipelines/Video/AVCaptureDeviceVideo'
    ss.dependency 'TSPrivacyKit/Pipelines/Video/AVCaptureSession'
    ss.dependency 'TSPrivacyKit/Pipelines/Video/AVCaptureStillImageOutput'
    ss.dependency 'TSPrivacyKit/Pipelines/Clipboard/UIPasteboard'
    ss.dependency 'TSPrivacyKit/Pipelines/IDFV/UIDeviceIDFV'
    ss.dependency 'TSPrivacyKit/Pipelines/Push/UNUserNotificationCenter'
    ss.dependency 'TSPrivacyKit/Pipelines/ScreenRecorder/RPSystemBroadcastPickerView'
    ss.dependency 'TSPrivacyKit/Impls/Consumer'
    ss.dependency 'TSPrivacyKit/NetworkModuleInterface'
    ss.dependency 'TSPrivacyKit/NetworkPipeline/TTNet'
    ss.dependency 'TSPrivacyKit/NetworkPipeline/URLProtocol'
    ss.dependency 'BDRuleEngine'
    ss.dependency 'BDRuleEngine/Privacy'
    ss.dependency 'PNSServiceKit/Service'
    ss.dependency 'PNSServiceKit/Protocol'
    ss.dependency 'PNSServiceKit/Impls'
    ss.dependency 'LarkSnCService'
    ss.dependency 'ThreadSafeDataStructure'
  end
  
  s.subspec 'InHouse' do |ss|
    ss.source_files = ['src/Sources/InHouse/**/**/*.{swift}']
    ss.dependency 'LarkPrivacyMonitor/Core'
    ss.dependency 'ShootsAPISocket'
  end

  s.test_spec 'Tests' do |ss|
    ss.source_files = 'src/Tests/**/*.{swift}'
    ss.xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym' # 从dsym里面解析case-文件的映射关系
    }
    ss.scheme = {
      :code_coverage => true, #开启覆盖率
      :environment_variables => {'UNIT_TEST' => '1'}, #单测启动环境变量
    }
    ss.dependency 'LarkSnCService'
  end

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
