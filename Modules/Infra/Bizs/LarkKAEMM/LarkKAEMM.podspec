 Pod::Spec.new do |s|
  s.name = 'LarkKAEMM'
  s.version = '5.10.19.5381347'
  s.author = { "huangjianming" => "huangjianming@bytedance.com" }
  s.license = 'MIT'
  s.homepage = 'git@code.byted.org:lark/ios-infra.git'
  s.summary = 'EMM ka指掌易依赖库'
  s.source = {:git => 'git@code.byted.org:lark/ios-infra.git', :tag => s.version.to_s}

  s.platform = :ios
  s.ios.deployment_target = "12.0"
  s.resource_bundles = {
    'LarkKAEMM' => ['resources/*'],
  }

  s.static_framework = true
  s.dependency 'RxSwift'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkAssembler'

  s.prepare_command = <<-CMD
    function download_framework() {
      name=$1
      url=$2
      path=$3

      # download file and unzip
      curl $url --output "./${name}.zip"
      unzip -oq "./${name}.zip" -d "${name}_files"

      # clean and create target dir
      [[ -d "./frameworks/${name}" ]] && rm -rf "./frameworks/${name}"
      mkdir -p "./frameworks/${name}"

      mv "./${name}_files/$path" "./frameworks/${name}"
      rm "./${name}.zip"
      rm -rf "./${name}_files"
    }

    download_framework ZZY http://tosv.byted.org/obj/ee-infra-ios/MBSSDK_Lite2.1_202204121039.zip output/frameworks
    download_framework VPN http://tosv.byted.org/obj/ee-infra-ios/SangforSDK_20211201.zip "SangforSDK.framework"
  CMD

  # for default_subspecs
  s.subspec 'Core' do |sub|
    sub.source_files = 'src/Core/**/*.{swift}'

    sub.dependency 'EENavigator'
    sub.dependency 'Swinject'
    sub.dependency 'LarkAccountInterface'
  end

  s.subspec 'ZZY' do |sub|
    sub.vendored_frameworks = 'frameworks/ZZY/frameworks/*.framework'
    sub.source_files = 'src/ZZY/**/*.{swift}'

    sub.dependency 'LarkKAEMM/Core'

    sub.dependency 'LarkAccountInterface'
    sub.dependency 'LarkAppConfig'
    sub.dependency 'LarkOPInterface'
    sub.dependency 'ECOProbe' # 不加编译不过😂
    sub.dependency 'LarkReleaseConfig'
    sub.dependency 'CryptoSwift'
    sub.dependency 'LarkSetting'

    sub.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D IS_NOT_DEFAULT' }
  end

  s.subspec 'VPN' do |sub|
    sub.vendored_frameworks = 'frameworks/VPN/*.framework'
    sub.source_files = 'src/VPN/**/*.{swift}'

    sub.dependency 'LarkKAEMM/Core'

    sub.dependency 'LarkAccountInterface'
    sub.dependency 'LarkAppConfig'
    sub.dependency 'LarkReleaseConfig'
    sub.dependency 'LKCommonsLogging'
    sub.dependency 'LarkSetting'
    sub.dependency 'BootManager'

    sub.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D IS_NOT_DEFAULT' }
  end

  s.subspec 'Custom' do |sub|
    sub.source_files = 'src/Custom/*.{swift}'
    sub.dependency 'LarkKAEMM/Core'
    sub.dependency 'LarkAccountInterface'
    sub.dependency 'LarkAppConfig'
    sub.dependency 'KAEMMService'
    sub.dependency 'LarkOPInterface'
    sub.dependency 'ECOProbe' # 不加编译不过😂
    sub.dependency 'LarkReleaseConfig'
    sub.dependency 'CryptoSwift'
    sub.dependency 'LarkSetting'
  end

  s.default_subspecs = 'Core'
end
