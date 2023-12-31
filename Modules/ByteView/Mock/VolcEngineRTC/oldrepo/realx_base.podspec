require 'json'

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'realx_base'
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

  current_dir = File.dirname(__FILE__)
  puts "running #{s.name}.podspec"

  # run sh first: download_sources.sh、build_third_party.sh、 prebuild.sh
  cmake_file = Dir.glob("#{current_dir}/ByteRTCSDK/build_ios/podspec/.cmake/api/v1/reply/target-#{s.name}-Release-*").first
  cmake_configs = JSON.parse(File.read(cmake_file))

  # https://sq.sf.163.com/blog/article/200385709022117888
  # https://pewpewthespells.com/blog/buildsettings.html
  pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD': 'c++14',
    'CLANG_CXX_LIBRARY': 'libc++',
    'USE_HEADERMAP': 'NO',
    'ENABLE_BITCODE': 'NO',
    'STRIPFLAGS': '-x',
    'GCC_ENABLE_CPP_EXCEPTIONS': 'YES',
    'GCC_ENABLE_CPP_RTTI': 'NO',
    'COMBINE_HIDPI_IMAGES': 'YES',
    'CLANG_ENABLE_OBJC_ARC': 'YES',
  }

  pod_target_xcconfig['OTHER_CFLAGS'] = ["-fstrict-aliasing", "-Wall", "-Wextra", "-Wno-unused-parameter", "-Wno-conversion", "-Wno-multichar", "-DNDEBUG", "-fPIC", "-Wthread-safety", "-fcolor-diagnostics", "-Werror", "-Wno-sign-compare", "-Wno-range-loop-analysis", "-Wno-missing-braces", "'-Wno-error=deprecated-declarations'", "'-Wno-error=thread-safety-analysis'", "'-Wno-error=unused-function'", "'-Wno-error=unused-private-field'", "'-Wno-error=unused-variable'", "'-Wno-error=missing-field-initializers'", "'-Wno-error=overloaded-virtual'", "'-fvisibility=hidden'", "-Wglobal-constructors", "$(inherited)"].join(' ')
  pod_target_xcconfig['OTHER_CPLUSPLUSFLAGS'] = ["-fno-c++-static-destructors", "-Wall", "-Wextra", "-Wno-unused-parameter", "-Wno-conversion", "-fvisibility=hidden", "-fvisibility-inlines-hidden", "-Wno-multichar", "-DNDEBUG", "-fPIC", "-Wthread-safety", "-fcolor-diagnostics", "-Werror", "-Wno-sign-compare", "-Wno-range-loop-analysis", "-Wno-missing-braces", "'-Wno-error=deprecated-declarations'", "'-Wno-error=thread-safety-analysis'", "'-Wno-error=unused-function'", "'-Wno-error=unused-private-field'", "'-Wno-error=unused-variable'", "'-Wno-error=missing-field-initializers'", "'-Wno-error=overloaded-virtual'", "'-fvisibility=hidden'", "-fexceptions", "-fno-rtti", "-Wglobal-constructors", "'-std=c++14'"].join(' ')

  # ["BYTERTC_IOS", "HAVE_PACKET_CRYPTO", "REALX_HAS_ACCELERATE", "REALX_LIBRARY_IMPL", "RTC_ENABLE_BYTEVC1", "RTC_ENABLE_BYTEVC1=1", "RTC_ENABLE_P2P", "RTC_PLATFORM_IOS=1", "RXJSON=rxjson", "RX_APPLE=1", "RX_ENABLE_AECLIVE=1", "RX_ENABLE_AUDIO=1", "RX_ENABLE_BYTENN=1", "RX_ENABLE_BYTEVC0=1", "RX_ENABLE_BYTEVC1DEC=1", "RX_ENABLE_BYTEVC1ENC=1", "RX_ENABLE_BYTEVC1SDEC=1", "RX_ENABLE_BYTEVC1SENC=1", "RX_ENABLE_IOS_AU_MERGE=1", "RX_ENABLE_IOS_AU_SPLIT=1", "RX_ENABLE_NETWORK_DETECT", "RX_ENABLE_NETWORK_DETECT=1", "RX_ENABLE_NICO=1", "RX_ENABLE_OpenH264=1", "RX_ENABLE_REPORT_EXTENDED=1", "RX_ENABLE_SPATIAL_AUDIO=1", "RX_ENABLE_SRTP", "RX_ENABLE_VIDEO=1", "RX_ENABLE_VIDEO_EXTERNAL_ENCODED=1", "RX_IOS=1", "RX_LOG_LEVEL_MODE=LOG_DEBUG", "RX_MODULE_NAME=Base", "RX_NS_FLOAT", "RX_PLATFORM_NAME=\"ios\"", "RX_POSIX=1", "RX_PROFILE_VC=1", "RX_PROFILE_VERTC=1", "USE_AUDIO_SAMPEL", "WEBRTC_EXCLUDE_BUILT_IN_SSL_ROOT_CERTS=1", "WEBRTC_IOS", "WEBRTC_MAC", "WEBRTC_NS_FIXED", "WEBRTC_POSIX", "__CLANG_SUPPORT_DYN_ANNOTATION__"]
  gcc_defines = cmake_configs['compileGroups'][0]['defines'].map { |f| f['define'].gsub("//", "/\\/") }.map { |f| f.include?('=') ? "'#{f}'" : f }
  arm_defines = ['RX_ARCH_ARM', 'REALX_HAS_NEON', 'WEBRTC_HAS_NEON', 'WEBRTC_ARCH_ARM', "'RX_ENABLE_NE10_FFT=1'"]
  arm64_defines = arm_defines + ['REALX_IS_AARCH64', 'WEBRTC_ARCH_ARM64']
  gcc_defines -= arm64_defines
  pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS'] = gcc_defines.join(' ')
  pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS[arch=armv7]'] = '$(inherited) ' + arm_defines.join(' ')
  pod_target_xcconfig['GCC_PREPROCESSOR_DEFINITIONS[arch=arm64]'] = '$(inherited) ' + arm64_defines.join(' ')
  
  pod_target_xcconfig['HEADER_SEARCH_PATHS'] = [
  "src",
  "src/realx/base", "src/realx/base/webrtc", "src/realx/base/ios",
  "third_party/jsoncpp/source/include",
  ].map { |f| "#{current_dir}/ByteRTCSDK/realx/#{f}" }

  pod_target_xcconfig['SYSTEM_HEADER_SEARCH_PATHS'] = [
  "abseil-cpp", "boringssl", "libyuv",
  ].map { |f| "#{current_dir}/third_party/#{f}/include" }

  s.pod_target_xcconfig = pod_target_xcconfig
#  pod_target_xcconfig.each { |k, v| puts "#{k}: #{v}" }

  s.libraries = 'c++'
  # s.frameworks = 'UIKit'

  source_files = cmake_configs['sources'].map { |f| "ByteRTCSDK/#{f['path']}" }.filter { |f| !f.end_with? 'webrtc/rtc_base/synchronization' }
  s.project_header_files = source_files.filter { |f| f.end_with? '.h' }
  s.source_files = source_files

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
