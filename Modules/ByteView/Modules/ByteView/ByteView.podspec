#
# Be sure to run `pod lib lint ByteView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'ByteView'
  s.version = '5.32.0.5486886'
  s.summary          = 'An iOS Module of ByteView Project. Which will provide basic fucti'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
办公套件中会议系统，代号 ByteView。 本仓库为其 iOS 平台组件库。
                       DESC

  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ByteView.iOS/tree/master/'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lvdaqian' => 'lvdaqian@bytedance.com' }
  s.source           = { :git => 'git@code.byted.org:ee/ByteView.iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.swift_version = '5.0'

  s.subspec 'CallKit' do |cs|
    cs.source_files = 'src/CallKit/**/*.{h,m,mm,swift}'
    cs.dependency 'ByteView/Core'
    cs.dependency 'SuiteCodable'
    cs.dependency 'LarkMedia'

    cs.frameworks = 'CallKit', 'PushKit'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D BYTEVIEW_CALLKIT' }
  end

  s.subspec 'Core' do |cs|
    cs.source_files = 'src/Core/**/*.{h,c,hpp,cpp,m,mm,swift}'
    cs.private_header_files = 'src/Core/**/*.hpp'
    cs.dependency 'ByteViewCommon'
    cs.dependency 'ByteViewTracker'
    cs.dependency 'ByteViewUI'
    cs.dependency 'ByteViewNetwork'
    cs.dependency 'ByteView/Resources'
    cs.dependency 'ByteView/RustSketch'
    cs.dependency 'ByteViewRTCRenderer'
    cs.dependency 'ByteViewMeeting'
    cs.dependency 'ByteViewSetting'
    cs.dependency 'ByteViewRtcBridge'

    cs.frameworks = 'CoreTelephony'
    cs.libraries = 'c++', 'resolv'

    cs.dependency 'RxSwift', '~> 5.0'
    cs.dependency 'RxCocoa', '~> 5.0'
    cs.dependency 'Action', '~> 4.0'
    cs.dependency 'SnapKit', '~> 5.0'
    cs.dependency 'NSObject+Rx'
    cs.dependency 'RxAutomaton'
    cs.dependency 'RxDataSources'
    cs.dependency 'ReachabilitySwift'
    cs.dependency 'RichLabel'
    cs.dependency 'EffectPlatformSDK'
    cs.dependency 'lottie-ios', '~> 2.0'
    cs.dependency 'LarkMedia'
    cs.dependency 'CryptoSwift'
    cs.dependency 'NotificationUserInfo'
    # cs.dependency 'VCInfra'
    cs.dependency 'LarkSegmentedView'
    cs.dependency 'AppReciableSDK'
    cs.dependency 'nfdsdk'
    # USE_DYNAMIC_RESOURCE
    cs.dependency 'LarkResource'
    cs.dependency 'ByteViewUDColor'
    cs.dependency 'UniverseDesignFont'
    cs.dependency 'UniverseDesignIcon'
    cs.dependency 'UniverseDesignShadow'
    cs.dependency 'UniverseDesignEmpty'
    cs.dependency 'UniverseDesignInput'
    cs.dependency 'UniverseDesignNotice'
    cs.dependency 'UniverseDesignDatePicker'
    cs.dependency 'UniverseDesignSwitch'
    cs.dependency 'UniverseDesignToast'
    cs.dependency 'UniverseDesignLoading'
    cs.dependency 'UniverseDesignActionPanel'
    cs.dependency 'LarkIllustrationResource'
    cs.dependency 'UniverseDesignCheckBox'
    cs.dependency 'Whiteboard'
    cs.dependency 'LarkSensitivityControl/API/DeviceInfo'
    cs.dependency 'LarkSensitivityControl/API/RTC'
    cs.dependency 'ByteViewWidget'
    cs.dependency 'ByteViewWidgetService'
    cs.dependency 'BDFishhook'
    cs.dependency 'LarkKeyCommandKit'
    cs.dependency 'LarkShortcut'
  end

  s.subspec 'Hybrid' do |cs|
    cs.source_files = 'src/Hybrid/**/*.swift'
    cs.dependency 'ByteView/Core'
    cs.dependency 'ByteViewHybrid'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D BYTEVIEW_HYBRID' }
  end

  s.subspec 'Configurations' do |cs|
    cs.source_files = 'src/configurations/**/*.{h,m,mm,swift}'
    cs.dependency 'LarkLocalizations'
    cs.resource_bundles = {
      'ByteViewAuto' => ['auto_resources/**/*']
    }
  end

  s.subspec 'Resources' do |cs|
    cs.source_files = 'src/Resources/**/*.{h,m,mm,swift}'
    cs.resources = ['resources/MainBundle/vc_call_ringing.mp3',
                    'resources/MainBundle/vc_call_ringing_spring.mp3',
                    'resources/MainBundle/meeting_count_down_end.aac',
                    'resources/MainBundle/meeting_count_down_remind.aac']
    cs.resource_bundles = {
      'ByteView' => ['resources/AE/*',
                     'resources/Sound/*',
                     'resources/simulcast/*',
                     'resources/Xibs/*',
                     'resources/Images.xcassets',
                     'resources/*.xcprivacy',
                     'resources/Lottie/*'],
    }
    cs.dependency 'ByteView/Configurations'
  end

  s.subspec 'RustSketch' do |cs|
    cs.source_files = 'src/RustSketch/include/rust_sketch.h'
    cs.vendored_libraries = 'src/RustSketch/lib/librustsketch.a'
    cs.dependency 'RustPB'
  end

  s.default_subspecs = 'Core'

  s.test_spec 'Tests' do |test_spec|
    test_spec.test_type = :unit
    test_spec.source_files = ['tests/**/*.{swift,h,m,mm,cpp}']
    test_spec.pod_target_xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
    }
    test_spec.scheme = {
      :code_coverage => true
    }
  end

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
    "bot": "d65ec628edd1434c885b2609210e941f"
  }

end
