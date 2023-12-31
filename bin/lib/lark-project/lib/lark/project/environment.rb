# frozen_string_literal: true

autoload :Versionomy, 'versionomy'

require 'json'
require 'lark/project'

# rubocop:disable Naming/PredicateName
module Lark
  module Project
    # environment config list
    # 集中存放Lark内可能用到的外部环境变量和相关配置，方便集中管控输入列表，保证一致性
    # also see hooks/appcenter_build.sh
    # KA 相关参数说明文档 https://bytedance.feishu.cn/docs/doccnbHsXYbNAgGNj8Zd4O8fIxg#
    #
    # NOTE: 这里面基本是一些只读的环境变量和需要统一的配置信息，不应该有副作用方法
    class Environment
      # @!method self.instance
      #  @return [Environment]
      include Singleton

      module VersionType
        POD = 'pod'
        SWIFT = 'swift'
      end

      def available?(type = VersionType::SWIFT, version)
        raise '不支持的版本信息' if version.nil? || version.empty?

        case type
        when VersionType::SWIFT
          EEScaffold::Swift.version
        when VersionType::POD
          Versionomy.parse(Pod::VERSION)
        else
          # type code here
          raise '不支持的类型，当前仅支持：VersionType::SWIFT、VersionType::POD'
        end >= Versionomy.parse(version)
      end

      def unavailable?(type = VersionType::SWIFT, version)
        !available?(type, version)
      end

      # lark平台统一最低兼容版本
      def deployment_target_ios
        '12.0'
      end

      # lark visionos 平台统一最低兼容版本
      def deployment_target_visionos
        '1.0'
      end

      def verbose?
        Lark::Misc.true? ENV['VERBOSE']
      end

      # modify by CI(hooks/appcenter_build.sh), release should be false
      def testable
        ENV['RUNTIME_TYPE'] != 'release'
      end

      # 发布环境，国内，海外，lite，ka等等
      # @return [String, nil]
      def lark_build_type
        ENV['LARK_BUILD_TYPE']
      end

      def appstore?
        ENV['BUILD_CHANNEL'] == 'appstore'
      end

      def is_oversea
        %w[international inhouse-oversea dev-oversea].include? lark_build_type
      end

      def is_inhouse
        !lark_build_type || lark_build_type.include?('inhouse')
      end

      # 是否CI环境
      def ci?
        ((ENV['FORCE_LOCAL'] || '') != 'true') and (!ENV['WORKFLOW_JOB_ID'].nil? or !ENV['JOB_NAME'].nil?)
      end

      # 是否本地研发环境
      def local?
        !ci?
      end

      def force_disable_statistic?
        ENV['LARK_FORCE_DISABLE_LLDB_STATISTIC'].to_s == 'true'
      end

      def bytest_autoLogin
        ENV['bytest_autoLogin'].to_s == 'true'
      end

      def bytest_package
        ENV['BYTEST_PACKAGE'].to_s == 'true'
      end

      def evil_method_enable
        ENV['EVIL_METHOD_ENABLE_V2'].to_s == 'true'
      end

      def evil_method_black_list
        ENV['EVIL_METHOD_BLACK_LIST'].to_s
      end

      def evil_method_white_list
        ENV['EVIL_METHOD_WHITE_LIST'].to_s
      end

      def should_strip_lang
        ENV['SHOULD_STRIP_LANG'] == '1'
      end

      def should_compress_i18n
        ENV['SHOULD_COMPRESS_I18n'] == '1'
      end

      def all_load_cost_enable
        ENV['IS_ALL_LOAD_COST_ENABLE'].to_s == 'true'
      end

      def flame_graph_enble
        ENV['IS_FLAME_GRAPH_ENABLE'].to_s == 'true'
      end

      def remote_cache_enable
        ENV['REMOTE_CACHE_ENABLE'].to_s == 'true'
      end

      # 是否是云打包
      def is_cloud_build
        ENV['SOURCE'].to_s == 'CLOUDBUILD'
      end

      # enable_single_module_llvm_emission开关
      def enable_single_module_llvm_emission
        ENV['LARK_SINGLE_MODULE_LLVM_EMISSION'].to_s == 'true'
      end

      # frame_outlining_enable开关 https://bytedance.feishu.cn/docx/CMp2dkrwMoWPuhxomcQcPvpqnSf
      def frame_outlining_enable
        ENV['LARK_FRAME_OUTLINING'].to_s == 'true'
      end

      # GMO生成开关 https://bytedance.feishu.cn/docx/QZHmdtnYEoGFbHx20C3cJIlrnaf
      def global_machine_outlining_summary_emit
        ENV['LARK_GMO_SUMMARY_EMIT'].to_s == 'true'
      end

      # GMO消费开关 https://bytedance.feishu.cn/docx/QZHmdtnYEoGFbHx20C3cJIlrnaf
      def global_machine_outlining_summary_consume
        ENV['LARK_GMO_SUMMARY_UTILIZE'].to_s == 'true'
      end

      # 代码覆盖率开关
      def code_coverage_enable
        ENV['CODE_COVERAGE_ENABLE'].to_s == 'true'
      end

      # 二进制重排开关
      def binary_reorder_enable
        ENV['BINARY_REORDER_ENABLE'].to_s == 'true'
      end

      # 二进制重排产物目录
      def bd_stake_output_dir
        ENV['BD_STAKE_OUTPUT_DIR']
      end

      # 线下代码覆盖率开关
      def offline_coverage_enable
        ENV['CODECOVERAGE']
      end

      # xcode版本
      def xcode_version
        ENV['XCODE_VERSION'].to_s
      end

      # 敏感api检查
      def lark_check_restricted
        ENV['LARK_CHECK_RESTRICTED'].to_s == 'true'
      end

      def lark_patch_dancecc_lldb
        ENV['LARK_PATCH_DANCECC_LLDB'].to_s == 'true'
      end

      # 自定义链接器，开关优先级：压缩链接器 > zld > ld64.lld
      # 自定义zld开关，如果压缩链接器开关打开，这项无效
      def lark_zld_enable
        ENV['LARK_ZLD_ENABLE'].to_s == 'true'
      end

      # 自定义lld开关，如果压缩链接器开关打开，这项无效
      def lark_lld_enable
        ENV['LARK_LLD_ENABLE'].to_s == 'true'
      end

      # 自定义kunld开关，如果压缩链接器开关打开，这项无效
      def lark_kunld_enable
        ENV['LARK_KUNLD_ENABLE'].to_s == 'true'
      end

      # 自定义jild开关，如果压缩链接器开关打开，这项无效
      def lark_jild_enable
        ENV['LARK_JILD_ENABLE'].to_s == 'true'
      end

      # 自定义编译驱动开关
      def lark_compiler_driver_enable
        ENV['LARK_COMPILER_DRIVER_ENABLE'].to_s == 'true'
      end

      # ExtensionCrashTracker开启开关
      def extension_crash_tracker_enable
        ENV['EXTENSION_CRASH_TRACKER_ENABLE'].to_s == 'true'
      end

      # 压缩链接器开关
      def zip_text_ld_enable
        ENV['ZIP_TEXT_LD_ENABLE'].to_s == 'true'
      end

      # text段迁移关闭开关
      def text_rename_close
        ENV['TEXT_RENAME_CLOSE'].to_s == 'true'
      end

      # ld outline开关
      def outline_ld_enable
        ENV['OUTLINE_LD_ENABLE'].to_s == 'true'
      end

      # LTO开关
      def lto_enable
        ENV['LTO_ENABLE'].to_s == 'true'
      end

      # 去除构建arch限制, 如为false则限制M1架构的机器只编译rosetta
      def build_for_all_arch
        ENV['BUILD_FOR_ALL_ARCH'].to_s == 'true'
      end

      # 对于开启LTO的组件，在本地编译/CI编译验证使用它的非LTO版本规避二次编译、提升链接速度
      def use_module_nolto(nolto_version, lto_version)
        ENV['LARK_USE_MODULE_NOLTO'].to_s == 'true' ? nolto_version : lto_version
      end

      # 二进制使用xcframework
      def use_xc_binary
        ENV['USE_XC_BINARY'].to_s == 'true'
      end

      # 任意门开关
      def anywhereDoorEnable?
        ENV['ANYWHEREDOOR'].to_s == 'true'
      end

      def check_arch_deps?
        Lark::Misc.true? ENV['CHECK_ARCH_DEPS']
      end

      # Merge修改的库
      def model_mr_list
        change_module = []
        if ENV.key?('CUSTOM_CI_MR_DEPENDENCIES')
          modelDic = JSON.parse(ENV['CUSTOM_CI_MR_DEPENDENCIES'])
          change_module += modelDic.keys
        end
        monorepo_path = "#{ENV['TARGETCODEPATH']}/main_repo_pods.json"
        if File.exist?(monorepo_path)
          monorepo_json = File.read(monorepo_path)
          monorepo_pod = JSON.parse(monorepo_json)
          change_module += monorepo_pod
        end
        change_module
      end

      # 热修复开关
      def hotpatch_enable
        ENV['HOTPATCH_ENABLE'].to_s == 'true'
      end

      # ENV: DEPLOY_MODE 是 Nest KA 构建任务新加的参数，标记 KA 类型
      # - hosted (专有)
      # - on-premise (私有)
      # - saas (saas定制的,不会下载init_configs, inti_settings)
      # https://bytedance.feishu.cn/docs/doccnbHsXYbNAgGNj8Zd4O8fIxg#
      def is_ka_login_mode
        ENV['LOGIN_TYPE'] == 'sso'
      end

      def is_ka?
        (ENV['BUILD_PRODUCT_TYPE'] || '').start_with?('KA')
      end

      alias is_ka is_ka?

      # inhouse、INSTALL_FEEDBACK为True、且非KA才可用
      def is_feedback_enable
        (ENV['INSTALL_FEEDBACK'] || '').to_s.downcase.start_with?('t') && !is_ka?
      end

      def is_ka_secsdk
        is_ka? && ['htone'].include?(ENV['KA_TYPE'].to_s)
      end

      def is_callkit_enable
        # %w[international inhouse inhouse-oversea].include? lark_build_type
        !is_ka?
      end

      # 非 oversea & 非 KA 可用
      def is_em_enable
        !is_oversea && !is_ka?
      end

      # TODO: 迁移去除 #
      def oversea(international, internal = {})
        feature(is_oversea, international, internal)
      end

      def ka_secsdk(ka_content, pub_content = {})
        feature(is_ka_secsdk, ka_content, pub_content)
      end

      def isAutoLogin(international, internal = {})
        feature(bytest_autoLogin, international, internal)
      end

      def feature(conditions, true_value, false_value = {})
        conditions ? true_value : false_value
      end

      # 是不是用来缓存二进制的Job
      def is_binary_cache_job
        ENV['CACHE_BINARY'] && ENV['CACHE_BINARY'].to_s == '1'
      end

      def is_build_with_binary
        ENV['IS_SWIFT_BINARY_CACHE_ENABLE'].to_s == 'true'
      end

      def can_change_module_stability
        #  明确使用swift 二进制，用于控制 CI 是否使用Swift二进制
        return ENV['USE_SWIFT_BINARY'].to_s == 'true' if ENV['USE_SWIFT_BINARY'].nil? == false

        # 非CI环境可以使用二进制
        return true if ENV['JOB_NAME'].nil? && ENV['CI_JOB_NAME'].nil?

        # 二进制缓存的Job 可以使用二进制，可以开启接口稳定
        return true if is_binary_cache_job || is_build_with_binary

        false
      end

      # block lynx devtool 开放开关
      def is_lynx_devtool_open
        ENV['OPEN_LYNY_DEVTOOL'] && ENV['OPEN_LYNY_DEVTOOL'].to_s == 'true'
      end

      def has_assert_patch?
        ENV['ASSERT_PATCH'].nil? ? testable : Lark::Misc.true?(ENV['ASSERT_PATCH'])
      end

      def switch_to_local_pod_enable
        # 初始环境变量拼写错了，这里兼容一下
        ENV['DIABLE_SWITCH_TO_LOCAL_POD'] != 'true' and ENV['DISABLE_SWITCH_TO_LOCAL_POD'] != 'true'
      end

      def alchemy_project_id
        ENV['ALCHEMY_PROJECT_ID']
      end
    end

    # 下面存放一些默认配置, 使用方有可能需要修改
    class Environment
      # rubocop:disable Metrics/MethodLength

      # 主工程通用的pod sources源
      def pod_sources
        @pod_sources ||= [
          # 优先查找组件平台的source
          'git@code.byted.org:iOS_Library/lark_source_repo.git',
          # make ours main source first
          'git@code.byted.org:ee/pods_specs.git',

          # old bd extension sources
          'git@code.byted.org:iOS_Library/privatethird_binary_repo.git',
          'git@code.byted.org:iOS_Library/privatethird_source_repo.git',
          'git@code.byted.org:iOS_Library/toutiao_source_repo.git',
          'git@code.byted.org:TTVideo/ttvideo-pods.git',
          'git@code.byted.org:iOS_Library/publicthird_binary_repo.git',
          'git@code.byted.org:iOS_Library/publicthird_source_repo.git',
          'git@code.byted.org:ugc/UGCSpecs.git',
          'git@code.byted.org:iOS_Library/IES-UGC_binary_repo.git',
          'git@code.byted.org:iOS_Library/douyin_binary_repo.git',
          'git@code.byted.org:ugc/AWESpecs.git',
          'git@code.byted.org:ugc/AWEReleaseBinarySpecs.git'
          # 这两个仓库就为了引入TSPrivacyKit, 感觉没必要，尽量缓存到我们的仓库
          # 'git@code.byted.org:ugc/AWEReleaseBinarySpecs.git',
          # 'git@code.byted.org:ugc/AWESpecs.git',

          # ours custom sources
          # 'git@code.byted.org:lark/pod_master_fork.git',
          # 'https://cdn.cocoapods.org/',
        ]
      end

      attr_writer :pod_sources,
                  :dynamic_framework_pods,
                  :international_only_list,
                  :internal_only_list,
                  :additional_header_include_config,
                  :allow_nonmodular_includes_target,
                  :append_swift_include_module,
                  :tobsdk_flags_target,
                  :mail_target,
                  :swift_objc_header_enable_target

      # ka原生集成涉及到需要变为动态库的list
      def ka_dynamic_pods
        ios_client_path = `git rev-parse --show-toplevel`.strip
        dynamic_pod_list_file = File.join(ios_client_path, 'bin/ka_resource_replace/ka_dynamic_pods_list')
        dynamic_pod_list = []
        if File.exist?(dynamic_pod_list_file) && !File.zero?(dynamic_pod_list_file)
          puts 'dynamic_pod_list_file not empty.'
          File.open(dynamic_pod_list_file, 'r').each_line do |line|
            dynamic_pod_list.append(line.strip)
          end
        end
        dynamic_pod_list
      end

      # default all framework should be static. here set the dynamic framework exception
      def dynamic_framework_pods
        alchemy_ka_pods_set = ka_dynamic_pods.to_set
        @dynamic_framework_pods ||= begin
          # @type [::Set]
          v = Set.new(%w[
            LarkHTTP
            MMKVCore
            MMKVAppExtension
            LarkStorageCore
            OCMock
            EEAtomic
            LKCommonsLogging
            LarkNotificationServiceExtension
            LarkExtensionServices
            RustSimpleLogSDK
            CryptoSwift
            NotificationUserInfo
            KAEMMService
            LKNativeAppExtension
            LKNativeAppExtensionAbility
            LKAppLinkExternal
            NativeAppPublicKit
            LKJsApiExternal
            LKKeyValueExternal
            LKQRCodeExternal
            LKKACore
            LKPassportExternal
            LKStatisticsExternal
            LKSettingExternal
            LKLoggerExternal
            LKPassportOperationExternal
            LKWebContainerExternal
            LKTabExternal
            LKMessageExternal
            LKKAContainer
            LKMenusExternal
          ]) + alchemy_ka_pods_set
          # @huangjianming, @cailiang.cl7r, @kongkaikai for all load cost test
          v.merge(%w[LKCommonsLogging AllLoadCost]) if all_load_cost_enable
          v
        end
      end

      # 主要用于修改三方动态库的buildSetting
      def dynamic_framework_third_pods
        %w[CryptoSwift MMKVAppExtension]
      end

      # The list of module name which only should use in international package.
      def international_only_list
        @international_only_list ||= %w[AppsFlyerFramework]
      end

      # The list of module name which only should use in internal package.
      def internal_only_list
        @internal_only_list ||= %w[AMapSearch BDUGShare]
      end

      def force_enable_module_names
        @force_enable_module_names ||= Set.new %w[
          CreationKitBeauty
          CreationKitRTProtocol
          DouyinOpenPlatformSDK
          NLEEditor
          TTPlayerSDK
          TTVideoEditor
          VCVodSettings
        ]
      end

      # TODO: 将来有空想办法把这类header问题自动修复
      # { target => additional header config }, config value:
      #       true: auto search all recursive_dependent_targets search paths, this may cause search path will long
      #       Array: a list of dep pods headers search path
      def additional_header_include_config
        @additional_header_include_config ||= {
          'BDAlogProtocol' => ['BDALog'],
          'CJComponents' => true,
          'CJPay' => true,
          'CJPayDebugTools' => true,
          'Heimdallr' => %w[BDAlogProtocol TTMacroManager BDALog SSZipArchive Stinger],
          'IESGeckoKitDebug' => ['IESGeckoKit'],
          'Lynx' => true,
          'SAMKeychain' => true,
          'TTBaseLib' => ['OpenUDID'],
          'TTNetworkManager' => ['Godzippa'],
          'TTVideoEditor' => %w[KVOController Heimdallr],
          'TTVideoEngine' => %w[TTPlayerSDK MDLMediaDataLoader],
          'TTVideoLive' => true,
          'byted_cert' => true,
          'TTMLeaksFinder' => ['FBRetainCycleDetector']
        }
      end

      # will inject CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES
      def allow_nonmodular_includes_target
        @allow_nonmodular_includes_target ||= Set.new %w[
          BDABTestSDK
          BDUGShare
          byted_cert
          ByteViewBoardcastExtension
          ByteViewMod
          CalendarMod
          CameraClient
          CJComponents
          CJPay
          CJPayDebugTools
          CookieManager
          EEMicroAppSDK
          Heimdallr
          IESGeckoKitDebug
          JsSDK
          LarkAccount
          LarkAccountAssembly
          LarkBaseService
          LarkBytedCert
          LarkByteView
          LarkChat
          LarkContact
          LarkCreateTeam
          LarkFinance
          LarkImageEditor
          LarkMessageCore
          LarkMessenger
          LarkMicroApp
          LarkOpenPlatform
          LarkOpenPlatformAssembly
          LarkSnsShare
          LarkTour
          LarkVideoDirector
          LarkStorageCore
          LarkStorage
          LarkWorkplace
          Lynx
          MessengerMod
          Minutes
          QRCode
          SAMKeychain
          SKBrowser
          SKDrive
          SKSpace
          TencentQQSDK
          TTMLeaksFinder
          TTNetworkManager
          TTVideoEditor
          WechatSDK
          WeiboSDK
          WorkplaceMod
        ]
      end

      # will inject CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES
      def append_swift_include_module
        @append_swift_include_module ||= {}
      end

      # will inject TOBSDK=1
      def tobsdk_flags_target
        @tobsdk_flags_target ||= %w[
          TTTracker
          LarkTracker
        ]
      end

      # will inject project_dir
      def mail_target
        @mail_target ||= %w[MailSDK]
      end

      # will inject SWIFT_INSTALL_OBJC_HEADER = YES
      def swift_objc_header_enable_target
        @swift_objc_header_enable_target ||= Set.new [
          'AnimatedTabBar',
          'ByteWebImage',
          'ECOInfra',
          'ECOProbe',
          'ECOProbeMeta',
          'EEMicroAppSDK',
          'EENavigator',
          'EcosystemWeb',
          'LKTracing',
          'LarkApp',
          'LarkCrashSanitizer',
          'LarkFlutterContainer',
          'LarkKeyCommandKit',
          'LarkMonitor',
          'LarkNavigation',
          'LarkOPInterface',
          'LarkOpenAPIModel', # 其他模块有该模块的class的oc-subclass
          'LarkOpenPluginManager', # 其他模块有该模块的class的oc-subclass
          'LarkOpenTrace',
          'LarkRustHTTP',
          'MLeaksFinder',
          'HTTProtocol', # 'BaseHTTProtocol' is superclass of 'RustHttpURLProtocol'
          'LarkTraitCollection',
          'LarkUIExtension',
          'LarkUIKit',
          'LarkVideoDirector',
          'LarkWaterMark',
          'LarkWebViewContainer',
          'LarkWebviewNativeComponent',
          'LarkwebViewNativeComponent',
          'OPBlock',
          'OPBlockInterface', # OPBlockEntityProtocol
          'OPFoundation',
          'OPGadget',
          'OPPluginBiz',
          'OPPluginManagerAdapter',
          'OPSDK',
          'OPJSEngine',
          'TTMicroApp',
          'UniverseDesignColor',
          'UniverseDesignEmpty',
          'UniverseDesignTheme',
          'bd_vessel',
          'flutter_keyboard_visibility',
          'meego_base_core',
          'meego_biz_plugin',
          'meego_common_ui',
          'meego_components_all',
          'meego_file_picker',
          'package_info',
          'shared_preferences',
          'uni_links',
          'url_launcher',
          'webview_flutter',
          'LarkKAAssembler',
          'SKUIKit',
          'UniverseDesignNotice',
          'UniverseDesignAvatar',
          'UniverseDesignInput',
          'UniverseDesignDialog',
          'LarkUIKit',
          'LarkWebViewContainer',
          'LarkAssetsBrowser',
          'LarkMenuController',
          'MSLoginFramework',
          'NativeAppPublicKit',
          'LKAppLinkExternal',
          'LKJsApiExternal',
          'LKKeyValueExternal',
          'LKKACore',
          'LKQRCodeExternal',
          'LarkStorageCore',
          'LarkStorage',
          'LKSettingExternal',
          'LKLoggerExternal',
          'LKPassportOperationExternal',
          'LKWindowManager',
          'LarkSensitivityControl',
          'LarkSecurityComplianceInfra',
          'LKStatisticsExternal',
          'LKWebContainerExternal',
          'FigmaKit',
          'LKTabExternal',
          'LKMessageExternal',
          'LKKAContainer',
          'LKMenusExternal'
        ]
      end

      def ignore_local_pod_names
        # 直接插入名字，无须写逗号和引号用空格或者换行符分割
        @ignore_local_pod_names ||= Set.new %w[]
      end

      def treat_warning_as_errors_list
        @treat_warning_as_errors_list ||= Set.new %w[
          EEAtomic
          EENavigator
          Homeric
          HTTProtocol
          LarkAssertConfig
          LarkCompatible
          LarkFileKit
          LarkFoundation
          LKCommonsLogging
          LKLoadable
          Logger
          SuiteCodable
          TTNetworkManager
          TTNetworkPredict
        ]
      end

      # rubocop:enable Metrics/MethodLength

      def support_binary_swift_version
        @support_binary_swift_version ||= Set.new [
          '5.7.1.135.3', # Xcode 14.1 RC 2、 # Xcode 14.1
          '5.7.2.135.5', # Xcode 14.2 RC 1、 # Xcode 14.2
          '5.8.0.124.2', # Xcode 14.3 RC 2、 # Xcode 14.3
          '5.8.0.124.5', # Xcode 14.3.1 RC 1、 # Xcode 14.3.1
          '5.9.0.128.106', # Xcode 15.0 Beta 7、Xcode 15.0 Beta 8
          '5.9.0.128.108', # Xcode 15.0 RC 2、 # Xcode 15.0、 # Xcode 15.0.1
          '5.9.2.2.56', # Xcode 15.1 RC 1、 # Xcode 15.1、 # Xcode 15.2 Beta 1
        ]
        # @support_binary_swift_version << '5.9.2.2.56' if ENV['LARK_TEST_BINARY_USER'] == 'true'
        # @support_binary_swift_version
      end

      def observe_compilation_time
        @observe_compilation_time ||= ENV['OBSERVE_COMPILATION_TIME'] == 'true'
      end

      # 架构检查相关的规则(hash格式)，看pod_group的说明文档
      attr_accessor :check_arch_rules
    end
  end
end
# rubocop:enable Naming/PredicateName
