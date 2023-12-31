# frozen_string_literal: true

#
# Be sure to run `pod lib lint ECOInfra.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'ECOInfra'
  s.version = '5.31.0.5456849'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'zhangmeng.94233'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.4'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.source_files = 'src/**/*.{h,m,mm,swift}'
  s.resource_bundles = {
      # 'ECOInfra' => ['resources/*.lproj/*', 'resources/*'],
      # 'ECOInfraAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  s.subspec 'ECOFoundation' do |ss|
    ss.source_files = 'src/ECOFoundation/**/*.{h,m,mm,swift}'

    ss.subspec 'MRC' do |sss|
      sss.requires_arc = false;
      sss.source_files = 'src/ECOFoundation/MRC/**/*.{h,m,swift}'
    end
    ss.dependency 'LarkSensitivityControl'
    ss.dependency 'LarkSetting'
  end

  s.subspec 'ECOStorage' do |ss|
    ss.source_files = 'src/ECOStorage/**/*.{h,m,mm,swift}'
    ss.dependency 'FMDB'
  end

  s.subspec 'ECONetwork' do |ss|
    ss.source_files = 'src/ECONetwork/**/*.{h,m,mm,swift}'

    ss.dependency 'TTNetworkManager'
    ss.dependency 'RustPB'
    ss.dependency 'RustSDK'
    ss.dependency 'LarkRustHTTP'
    ss.dependency 'ECOProbe'
    ss.dependency 'SwiftyJSON'
  end
  
  s.subspec 'OPError' do |ss|
    ss.source_files = 'src/OPError/**/*.{swift,h,m}'
    ss.dependency 'ECOProbe'
  end

  s.subspec 'ECOCookie' do |ss|
    ss.source_files = 'src/ECOCookie/**/*.{h,m,mm,swift}'

    ss.dependency 'ECOInfra/ECOFoundation'
    ss.dependency 'ECOInfra/ECOConfig'

    ss.dependency 'LKCommonsLogging'
    ss.dependency 'LarkFoundation'
    ss.dependency 'CryptoSwift'
    ss.dependency 'LarkSetting'
  end

  s.subspec 'ECOSandbox' do |ss|
    ss.source_files = 'src/ECOSandbox/**/*.{h,m,mm,swift}'
  end

  s.subspec 'ECOConfig' do |ss|
    ss.source_files = 'src/ECOConfig/**/*.{h,m,mm,swift}'

    ss.dependency 'ECOInfra/ECOFoundation'
    ss.dependency 'LarkSetting'
    ss.dependency 'FMDB'
    ss.dependency 'ReachabilitySwift'
  end

  s.subspec 'ECODevTool' do |ss|
    ss.source_files = 'src/ECODevTool/**/*.{h,m,mm,swift}'
  end

  s.dependency 'Swinject'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkContainer'
  s.dependency 'ECOProbe'
  s.dependency 'ECOProbeMeta'
  # s.dependency 'AFNetworking', '~> 2.3'
  # s.dependency 'LarkLocalizations'

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

  s.test_spec 'Tests' do |ts|
        ts.source_files = 'Tests/**/*.{swift,m}'#根据单测代码决定
        ts.requires_app_host = true
        ts.xcconfig = {
          'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym' #需要dsym
        }

        ts.scheme = {
          :code_coverage => true,#开启覆盖率
          :environment_variables => {'UNIT_TEST' => '1'},#单测启动环境变量
          :launch_arguments => [] #测试启动参数
        }
      end
end
