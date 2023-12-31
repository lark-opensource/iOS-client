require 'json'
require './VolcSubmodules.rb'

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'VolcEngineRTC'
  s.version          = '5.9.0.1'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'email'
  }

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  current_dir = File.dirname(__FILE__)
  puts "running #{s.name}.podspec"
  puts "current dir is #{current_dir}"

  local_pods = VolcSubmodules.get
  puts "local_pods = #{local_pods}"

  # run sh first: download_sources.sh、build_third_party.sh、 prebuild.sh
  cmake_targets = Dir.glob("#{current_dir}/ByteRTCSDK/build_ios/podspec/.cmake/api/v1/reply/target-*-Release-*")
  core_cmake_file = cmake_targets.find { |f| File.basename(f).start_with? "target-#{s.name}-" }
  cmake_obj = JSON.parse(File.read(core_cmake_file))

  # https://sq.sf.163.com/blog/article/200385709022117888
  pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD': 'gnu++14',
    'CLANG_CXX_LIBRARY': 'libc++',
    'DEFINES_MODULE': 'YES',
    'USE_HEADERMAP': 'NO',
    'ENABLE_BITCODE': 'NO',
    'DEPLOYMENT_POSTPROCESSING': 'YES',
    'STRIPFLAGS': '-x',
    'COPY_PHASE_STRIP': 'NO',
    'STRIP_INSTALLED_PRODUCT': 'NO',
    'STRIP_STYLE': 'debugging',
    'STRIP_SWIFT_SYMBOLS': 'NO',
    'COMBINE_HIDPI_IMAGES': 'YES',
    'ENABLE_STRICT_OBJC_MSGSEND': 'YES',
    'EXPORTED_SYMBOLS_FILE': "#{current_dir}/ByteRTCSDK/sdk/ios/ByteRtcEngineKit/export-meeting.txt",
    'GCC_ENABLE_CPP_EXCEPTIONS': 'YES',
    'GCC_ENABLE_CPP_RTTI': 'NO',
    'GCC_WARN_ABOUT_RETURN_TYPE': 'NO',
    # Symbols Hidden by Default
    'GCC_SYMBOLS_PRIVATE_EXTERN': 'YES',
    'LD_GENERATE_MAP_FILE': 'YES',
    # Perform Single-Object Prelink
    'GENERATE_MASTER_OBJECT_FILE': 'YES',
    'PRELINK_FLAGS': '-ObjC',
  }

#  pod_target_xcconfig['OTHER_LDFLAGS'] = "$(inherited) -Wl,-search_paths_first -ObjC -Wl,-rename_section,__TEXT,__text,__BD_TEXT,__text -Wl,-rename_section,__TEXT,__textcoal_nt,__BD_TEXT,__text -Wl,-rename_section,__TEXT,__StaticInit,__BD_TEXT,__text -Wl,-rename_section,__TEXT,__stubs,__BD_TEXT,__stubs -Wl,-rename_section,__TEXT,__picsymbolstub4,__BD_TEXT,__picsymbolstub4 -Wl,-rename_section,__TEXT,__stub_helper,__BD_TEXT,__stub_helper -Wl,-rename_section,__TEXT,__objc_classname,__BD_TEXT,__objc_classname -Wl,-rename_section,__TEXT,__objc_methname,__BD_TEXT,__objc_methname -Wl,-rename_section,__TEXT,__cstring,__BD_TEXT,__cstring -Wl,-segprot,__BD_TEXT,rx,rx -Wl,-rename_section,__TEXT,__const,__COMPRESS,__const -Wl,-rename_section,__TEXT,__objc_methtype,__COMPRESS,__objc_methtype -Wl,-rename_section,__TEXT,__gcc_except_tab,__COMPRESS,__gcc_except_tab -Wl,-segprot,__COMPRESS,r,r"
  pod_target_xcconfig['OTHER_LDFLAGS'] = ["$(inherited)", "-Wl,-search_paths_first", "-ObjC"].join(' ')
  pod_target_xcconfig['OTHER_CFLAGS'] = ["$(inherited)", "-fstrict-aliasing", "-Wall", "-Wextra", "-Wno-unused-parameter", "-Wno-conversion", "-Wno-multichar", "-DNDEBUG", "-fobjc-arc", "-Wno-cpp", "-Wno-error=writable-strings", "-Wno-error=deprecated-declarations"].join(' ')
  pod_target_xcconfig['OTHER_CPLUSPLUSFLAGS'] = ["$(inherited)", "-fno-c++-static-destructors", "-Wall", "-Wextra", "-Wno-unused-parameter", "-Wno-conversion", "-fvisibility=hidden", "-fvisibility-inlines-hidden", "-Wno-multichar", "-DNDEBUG", "-fobjc-arc", "-fexceptions", "-fno-rtti", "-Wno-cpp", "-Wno-error=writable-strings", "-Wno-error=deprecated-declarations"].join(' ')

  gcc_defines = cmake_obj['compileGroups'][0]['defines'].map { |f| f['define'].gsub("//", "/\\/") }.map { |f| f.include?('=') ? "'#{f}'" : f }
  pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] = gcc_defines.join(' ')

  prelink_libs = [
    'opus', 'NICO', 'bytevc0', 'bytevc1dec', 'bytevc1enc', 'boya', 'protobuf-lite', 'jsoncpp', 'srtp2', 'z',
    'openh264',
    'realx_base',
    'realx_audio_main',
    'realx_video_main',
    'realx_network_main',
    'realx',
    'realx_engine',
    'byteaudio_engine', 'byteaudio_static',
    'webrtc_p2p',
  ]
  prelink_libs -= local_pods
  prelink_libs = prelink_libs.map { |f| "#{current_dir}/third_party/#{f}/lib/lib#{f}.a" }
  prelink_libs += [
    'boringssl/lib/libcrypto.a',
    'boringssl/lib/libssl.a',
    'ne10/lib/libNE10.a',
  ].map { |f| "#{current_dir}/third_party/#{f}" }
  prelink_libs += local_pods.map { |f| "${BUILT_PRODUCTS_DIR}/../#{f}/#{f}.framework/#{f}" }
  pod_target_xcconfig['PRELINK_LIBS'] = prelink_libs.join(' ')

  pod_target_xcconfig['SYSTEM_HEADER_SEARCH_PATHS'] = [
    'abseil-cpp',
    'boringssl',
    'libyuv',
    'openh264',
    'bytevc0',
    'bytevc1enc',
    'bytevc1dec',
    'bytenn',
    'opus',
    'NICO',
  ].map { |f| "#{current_dir}/third_party/#{f}/include" }.join(' ') + ' $(inherited)'

  header_search_paths = [
    "#{current_dir}/ByteRTCSDK",
  ]
  [
    'api',
    'src',
    'src/realx/api',
    'src/realx/audio',
    'src/realx/audio/nodes/audio_device/ios',
    'src/realx/base',
    'src/realx/base/ios',
    'src/realx/base/webrtc',
    'src/realx/engine',
    'src/realx/webrtc_impl',
    'third_party',
    'third_party/boya/include',
    'third_party/boya/include/vc',
    'third_party/webrtc/sdk/objc',
    'third_party/jsoncpp/source/include',
  ].each { |f| header_search_paths.append("#{current_dir}/ByteRTCSDK/realx/#{f}") }
  [
    'modules/third_party/cvlab/inc',
    'modules/third_party/innerEffHeader/effect/mobile-inc',
    'modules/third_party/smash',
    'rtc',
    'rtc/base',
    'rtc/engine',
    'rtc/engine/native/meeting',
    'rtc/media',
    'rtc/media/ios',
    'rtc/media/pc_desktop_capture',
    'rtc/third_party',
    'rtc/third_party/zlib-1.2.11',
    'rtc/util',
    'rtc/util/logsdk/src',
    'rtc/util/logsdk/src/module_intact',
    'rtc/util/logsdk/thirdparty/proto/src',
    'sdk/ios',
    'sdk/ios/ByteRtcEngineKit',
    'src/sdk/meeting',
    'src/sdk/native/meeting',
    'src/sdk/native/rtc',
    'src/sdk/native/rts',
    'src/sdk/objc/rtc',
  ].each { |f| header_search_paths.append("#{current_dir}/ByteRTCSDK/#{f}") }
  Dir.glob("#{current_dir}/ByteRTCSDK/rtc/third_party/boost_1_69_0/boost/*/include").each { |f| header_search_paths.append(f) }
  pod_target_xcconfig['HEADER_SEARCH_PATHS'] = header_search_paths

  s.pod_target_xcconfig = pod_target_xcconfig
  s.module_map = 'framework/module.modulemap'

  s.script_phase = {
    'name': 'Copy Framework Headers',
    'script': <<-CMD
      echo 'copy VolcEngineRTC headers into framework'
      cp -r "#{current_dir}/framework/Headers" "${BUILT_PRODUCTS_DIR}/#{s.name}.framework/Headers"
    CMD
  }

  s.libraries = 'c++'
  s.frameworks = [
    'Foundation',
    'UIKit',
    'CoreTelephony',
    'SystemConfiguration',
    'Metal',
    'MetalPerformanceShaders',
    'Accelerate',
    'Security',
    'ReplayKit',
    'Network',
    'QuartzCore',
    'OpenGLES',
    'GLKit',
    'AVFoundation',
    'VideoToolbox',
    'CoreVideo',
    'AudioToolbox',
    'CoreAudio',
    'CoreMedia',
    'CoreGraphics',
    'CoreML',
  ]

  local_subspecs = [
    'rtc_base',
#    'realx',
#    'realx_base',
#    'realx_engine',
#    'realx_audio_main',
#    'realx_video_main',
#    'realx_network_main',
#    'byteaudio_engine',
#    'byteaudio_static',
#    'webrtc_p2p',
    'websocket_client',
#    'libprotobuf-lite',
#    'boya',
#    'jsoncpp',
    'kcp',
#    'srtp2',
#    'zlibstatic',
  ]

  s.subspec 'Core' do |cs|
    local_subspecs.each { |f| cs.dependency "#{s.name}/#{f}" }
    local_pods.each { |f| cs.dependency f }

    # https://github.com/CocoaPods/CocoaPods/issues/8289
    # install! 'cocoapods', :deterministic_uuids => false
    source_files = cmake_obj['sources'].map { |f| "ByteRTCSDK/#{f['path']}" }

    cs.project_header_files = source_files.filter { |f| f.end_with? '.h' }
    cs.source_files = source_files
  end

  local_subspecs.each do |target_name|
    s.subspec target_name do |cs|
      cmake_file = cmake_targets.find { |f| File.basename(f).start_with? "target-#{target_name}-" }
      source_files = JSON.parse(File.read(cmake_file))['sources'].map { |f| "ByteRTCSDK/#{f['path']}" }
      cs.project_header_files = source_files.filter { |f| f.end_with? '.h' }
      cs.source_files = source_files
    end
  end

  s.default_subspecs = ['Core']
  #s.vendored_libraries = ['openh264'].map { |f| "third_party/#{f}/lib/lib#{f}.a" }

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
