# frozen_string_literal: true

require 'lark/project/if_pod_helper'

# rubocop:disable Layout/LineLength, Metrics/MethodLength
module Pod
  # 这个文件里存放所有的版本限制，和可选集成依赖
  # 这个文件里的配置，可以被Podfile的配置覆盖
  # 这里面如果定义方法，需要使用lark_的前缀，避免子仓命名冲突
  class Podfile
    using IfPodRefine
    # 这下面使用的if_pod会保存到if_pod_cache里，延迟生效.
    # (因此如果Podfile里有定义，Podfile的定义优先)
    # NOTE: 这里不应该使用pod引入根依赖。根依赖在Podfile里声明

    # lark主App需要依赖的版本和条件集成
    def lark_main_target_if_pods
      lark_businessPods
      lark_pods
      lark_commonPods
      lark_universeDesignPods
      lark_thirdPartyPods
      lark_debugPods
      lark_toutiaoPods
      lark_flutterPods
    end

    def lark_ecosystemAndWebAndWebFunctionalPods
      # 生态系统仓库 start
      if_pod 'LarkMicroApp', '5.5.0.1' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'LarkTabMicroApp', '5.1.0.1' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'LarkAppCenter', '5.6.0.3' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'LarkAppLinkSDK', '5.5.0.1' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'EEMicroAppSDK', '5.6.0.1' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'TTMicroApp', '5.6.0.4' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'SocketRocket', :source => 'git@code.byted.org:ee/pods_specs.git' # 这里发现 TTMicroApp 依赖了 SocketRocket, 默认是用的是Github的代码，bit会有兼容问题
      if_pod 'LarkOPInterface', '5.2.0.1' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPSDK', '5.5.0.3' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPGadget', '5.5.0.1' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPFoundation', '5.1.0.1' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPBlock', '5.6.0.1' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPBlockInterface', '5.5.0.1' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPPlugin', '5.6.0.3' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'NewLarkDynamic', '5.1.0.2' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      # ECOInfra
      if_pod 'ECOInfra', '5.5.0.3' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'ECOProbe', '5.0.0.6' # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'ECOProbeMeta', '1.0.67' # 「OPMonitor埋点代码生成工具」根据「OPMonitor埋点元数据」生成的「OPMonitor埋点代码」仓库
      # OpenAPI
      if_pod 'LarkOpenPluginManager', '5.6.0.4' # 开放API Pod，请不要手动修改开放API Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'LarkOpenAPIModel', '5.6.0.1' # 开放API Pod，请不要手动修改开放API Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      # web pods
      if_pod 'LarkWebViewContainer', '5.5.0.1' # 套件统一WebView，请不要手动修改套件统一WebViewPod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'WebBrowser', '5.5.0.3' # 套件统一浏览器，请不要手动修改套件统一浏览器Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'EcosystemWeb', '5.6.0.3' # Ecosystem Client Native Web Business，请不要手动修改EcosystemWeb Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPWebApp', '5.5.0.4' #套件统一WebView，请不要手动修改套件统一WebViewPod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      # 生态系统仓库 end
      # web functional pods
      if_pod 'LarkWebviewNativeComponent', '5.4.0.1' # 套件统一WebView同层渲染
      if_pod 'LarkWebCache', '3.41.4'
      # 服务台/oncall/HelpDesk
      if_pod 'HelpDesk', '5.1.0.2' # HelpDesk，请不要手动修改 HelpDesk Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'EcosystemShell', '5.6.0.3' # bits的占位仓库，仅对Ecosystem壳工程进行了修改需要在bits平台上进行合码时，选择此组件进行升级即可
    end

    def lark_larkMessengerPods
      # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能，相关文档：https://bytedance.feishu.cn/wiki/wikcnJzs27QgWQippNuElSOey9c
      if_pod 'MessengerMod', '5.5.0.1'
      if_pod 'LarkAttachmentUploader', '5.4.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能 # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFeed', '5.6.0.2' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFeedBanner', '5.6.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFeedPlugin', '5.5.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkMine', '5.6.0.2' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkUrgent', '5.5.0.2', **$lark_env.feature($lark_env.is_em_enable, {
        subspecs: ['Core', 'EMC', 'EMD']
      }, {
        subspecs: ['Core', 'EMC']
      }) # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFinance', '5.6.0.2', **$lark_env.oversea({ subspecs: ['Core'] }, { subspecs: %w[Core Pay] }) # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkChat', '5.6.0.6' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkChatSetting', '5.6.0.2' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFile', '5.6.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkThread', '0.0.0.18' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkContact', '5.6.0.6' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSearch', '5.6.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSearchCore', '5.5.0.12' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkAI', '5.6.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkMessageCore', '5.6.0.6' # , :testspecs => ['Tests']  # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSearchFilter', '5.5.0.2' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkForward', '5.5.0.5' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkAudio', '5.4.0.9' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkCore', '5.6.0.3' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkQRCode', '5.5.0.3' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkMessengerInterface', '5.6.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSDK', '5.6.0.5' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSDKInterface', '5.6.0.4' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkEdu', '5.6.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'Moment', '5.6.0.3' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkTeam', '5.6.0.2' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'DynamicURLComponent', '5.6.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'BitsPodsPlaceholder', '5.5.0.10' # 占位仓库，没有实际代码
    end

    def lark_spacekitPods
      if_pod 'CCMMod', '5.5.0.5' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKResource', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKFoundation', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKUIKit', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKCommon', '5.6.0.1' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKBrowser', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKDoc', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKSheet', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKBitable', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKMindnote', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKSlide', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKWiki', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKWikiV2', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SpaceKit', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SpaceInterface', '5.5.0.5' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKSpace', '5.5.0.5' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKDrive', '5.5.0.4' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'PDFiumKit', '1.1.17'

      if_pod 'SQLiteMigrationManager.swift', '0.8.0'
      if_pod 'SQLite.swift', '0.13.0'
      if_pod 'LibArchiveKit', '1.2.0'
    end

    def lark_calendarPods
      if_pod 'CalendarMod', '5.6.0.1'
      if_pod 'Calendar', '5.6.0.3' # 请不要手动修改calendarPods业务库的版本号，使用bits多仓MR集成功能
      if_pod 'CalendarFoundation', '5.5.0.1' # 请不要手动修改calendarPods业务库的版本号，使用bits多仓MR集成功能
      if_pod 'CalendarRichTextEditor', '5.5.0.2' # 请不要手动修改calendarPods业务库的版本号，使用bits多仓MR集成功能
      if_pod 'TodoMod', '5.4.0.2'
      if_pod 'Todo', '5.6.0.2' # 请不要手动修改lark_calendarPods业务库的版本号，使用bits多仓MR集>成功能
      if_pod 'TodoInterface', '5.5.0.1' # 请不要手动修改lark_calendarPods业务库的版本号，使用bits多仓MR集成功能
      if_pod 'CTFoundation', '5.0.0.1' # 请不要手动修改lark_calendarPods业务库的版本号，使用bits多仓MR集成功能
    end

    # Lark 定制版，如需更新请联系 Ecosystem, AI & Search, 钱包等业务
    def lark_pod_lynx
      lynx_version = '2.1.1-alpha.233.3-bugfix.1.binary'
      lynx_config = $lark_env.is_oversea ? 'BDConfig/OS' : 'BDConfig/CN'
      if_pod 'XElement', lynx_version, subspecs: %w[
        Swiper
        Input
        Picker
        Text
        ScrollView
        SVG
      ]
      if_pod 'Lynx', lynx_version, subspecs: %W[
        Framework
        Native
        JSRuntime
        ReleaseResource
        Canvas/core
        Canvas/helium
        #{lynx_config}
      ]
      if_pod 'LynxDevtool', lynx_version
      if_pod 'Napi', '2.0.2', subspecs: %W[
        Core
        Env
        JSC
      ]
      if_pod 'vmsdk', '0.0.11-r2d1', subspecs: %W[
        quickjs
      ]
      # 固定HeliumEffectAdapterHeader的版本，否则会编译报错
      if_pod 'HeliumEffectAdapterHeader', '0.1.1'
    end

    def lark_businessPods
      lark_larkMessengerPods
      lark_spacekitPods
      lark_calendarPods
      lark_ecosystemAndWebAndWebFunctionalPods

      if_pod 'ByteWebImage', '5.6.0.2', subspecs: %w[Core Lark]
      if_pod 'LarkWaterMark', '0.2.31'
      if_pod 'LarkAvatar', '0.22.56'
      if_pod 'MailSDK', '5.5.0-beta.1' #:path => '../mail-ios-client/MailSDK', :inhibit_warnings => false
      if_pod 'LarkEditorJS', '5.5.2'
      if_pod 'LarkBizAvatar', '0.12.40'
      if_pod 'LarkAvatarComponent', '0.13.39'
      if_pod 'AvatarComponent', '0.12.4'
      if_pod 'LarkZoomable', '0.3.0'
      if_pod 'LarkMailInterface', '0.1.0-alpha.5'
      if_pod 'UltrasonicWave', '0.2.3'
      if_pod 'ByteViewMod', '5.5.0.8'
      if_pod 'ByteViewInterface', '5.4.0.1'
      if_pod 'ByteViewRTCRenderer', '5.4.0.3'
      if_pod 'ByteViewUDColor', '0.1.18'
      if_pod 'LarkVoIP', '5.1.0.6'
      if_pod 'ByteViewMessenger', '5.5.0.4'
      if_pod 'ByteViewDependency', '5.5.0.1'
      if_pod 'ByteViewCommon', '5.5.0.5'
      if_pod 'ByteViewTracker', '5.3.0.1'
      if_pod 'ByteViewUI', '5.4.0.3'
      if_pod 'ByteViewNetwork', '5.5.0.9'
      if_pod 'ByteViewTab', '5.5.0.8'
      if_pod 'ByteViewParticipantBuilder', '5.5.0.2'
      if_pod 'ByteView', '5.5.0.87', **$lark_env.feature($lark_env.is_callkit_enable, {
                           subspecs: %w[Core CallKit]
                         }, {
                           subspecs: ['Core']
                         })
      if_pod 'AudioSessionScenario', '0.7.8', **$lark_env.feature($lark_env.testable || $lark_env.is_binary_cache_job, {
                             subspecs: %w[Core Boot Debug]
                           }, {
                             subspecs: %w[Core Boot]
                           })
      if_pod 'LarkRVC', '0.1.2'
      if_pod 'EffectPlatformSDK', '2.9.147', subspecs: %w[Core ModelDistribute]
      if_pod 'EffectSDK_iOS', '9.9.0.60-lark.1.binary'
      if_pod 'bytenn-ios', '2.10.87'
      if_pod 'AGFX_pub', '10.60.0.7'
      if_pod 'VCInfra', '0.1.4'
      if_pod 'AppReciableSDK', '0.1.40'
      if_pod 'JTAppleCalendar', '7.1.7'
      lark_pod_bullet
      lark_pod_lynx
      if_pod 'HTTProtocol', '0.22.10'
      if_pod 'LarkRustHTTP', '0.25.5'
      if_pod 'LarkAccountInterface', '5.3.0.1', inhibit_warnings: false
      if_pod 'LarkAccountInterface', :pods => ['LarkAccount'], inhibit_warnings: false

      # About is_ka_login_mode: $(git rev-parse --show-toplevel)/bin/lib/lark-project/lib/lark/project/environment.rb
      if_pod 'LarkAccount', '5.6.0.6', **$lark_env.feature($lark_env.is_ka_login_mode, {
        subspecs: %w[Core Authorization IDP RustPlugin NativePlugin TuringCN KA BootManager]
      }, $lark_env.oversea({
          subspecs: %w[Core Authorization IDP RustPlugin NativePlugin TuringOversea BootManager]
        }, $lark_env.isAutoLogin({
            subspecs: %w[Core Authorization IDP RustPlugin NativePlugin TuringCN OneKeyLogin BootManager bytestAutoLogin]
          }, {
              subspecs: %w[Core Authorization IDP RustPlugin NativePlugin TuringCN OneKeyLogin BootManager]
            })))

      if_pod 'LarkSecurityAudit', '5.2.0.1', subspecs: %w[Core Assembly Authorization]
      if_pod 'LarkAppConfig', '3.41.66', inhibit_warnings: false
      if_pod 'LarkEnv', '3.41.8', inhibit_warnings: false
      if_pod 'LarkKAFeatureSwitch', '3.41.22', inhibit_warnings: false
      if_pod 'LarkExtensionMessage', '3.41.8'
      if_pod 'LarkMessageBase', '3.42.72', inhibit_warnings: false
      if_pod 'Blockit', '5.6.0.1', inhibit_warnings: false
      if_pod 'LarkNavigation', '4.0.118'
      if_pod 'LarkNavigator', '3.38.10', inhibit_warnings: false
      if_pod 'LarkSplitViewController', '0.15.69', inhibit_warnings: false
      if_pod 'LarkNotificationServiceExtensionLib', '3.26.1',
             inhibit_warnings: false
      if_pod 'LarkPerf', '3.41.16', inhibit_warnings: false
      if_pod 'LarkAppResources', '3.38.15'
      if_pod 'LarkIllustrationResource', '0.0.11'
      if_pod 'LarkWidgetService', '1.1.18'
      if_pod 'LarkWebCache', '3.41.4'
      if_pod 'LarkButton', '0.22.6'
      if_pod 'LarkLocalizations', '1.16.11'
      if_pod 'RichLabel', '0.22.27'
      if_pod 'LarkReleaseConfig', '0.23.5'
      if_pod 'QRCode', '100.13.47'
      if_pod 'LarkBadge', '0.24.13'
      if_pod 'LarkAccount', :pods => ['LarkLaunchGuide', 'LKLaunchGuide', 'LarkPrivacyAlert', 'LarkPolicySign']
      if_pod 'LarkLaunchGuide', '4.0.14'
      if_pod 'LKLaunchGuide', '3.41.26'
      if_pod 'LarkPrivacyAlert', '3.42.28'
      if_pod 'LarkPolicySign', '3.44.15'
      if_pod 'LarkTourInterface', '3.42.0'
      if_pod 'LarkTourInterface', :pods => ['LarkTour']
      if_pod 'LarkTour', '3.43.45'
      if_pod 'LarkQuaterback', '0.2.7', **$lark_env.oversea({ subspecs: ['overseas'] }, { subspecs: ['domestic'] })
      if_pod 'Quaterback', '2.2.1'
      if_pod 'LarkCustomerService', '0.23.2'
      if_pod 'LarkLocationPicker', '0.23.35', **$lark_env.oversea({ subspecs: ['OverSeaDependency'] }, { subspecs: ['InternalDependency'] })
      if_pod 'LarkReactionView', '0.22.34'
      if_pod 'LarkReactionDetailController', '0.22.19'
      if_pod 'LarkMenuController', '0.22.30'
      if_pod 'LarkSafety', '0.22.1'
      if_pod 'LarkDatePickerView', '3.41.41'
      if_pod 'SelectMenu', '0.23.29'
      if_pod 'LarkTimeFormatUtils', '5.6.0.1'
      if_pod 'OfflineResourceManager', '0.22.11'
      if_pod 'EEImageMagick', '0.1.2'
      if_pod 'LarkSuspendable', '0.5.13'
      if_pod 'SecSDK', '1.4.6'
      if_pod 'LarkSettingsBundle', '3.41.4'
      if_pod 'LarkSetting', '0.0.77', subspecs: %w[Core LarkAssemble]

      if_pod 'LarkBanner', '100.13.44'
      if_pod 'LarkCache', '0.12.14', subspecs: %w[Core CryptoRustImpl]
      if_pod 'LarkTab', '0.2.10'
      if_pod 'LarkEmotionKeyboard', '0.1.39'
      if_pod 'LarkOuterTest', '0.0.21'

      if_pod 'BDASplashSDKI18N', '0.2.18.1-binary', subspecs: ['Core']
      if_pod 'TTAdSplashSDK', '0.7.26.5-bugfix.1-binary', subspecs: ['Core']
      if_pod 'LarkSplash', '0.6.45', **$lark_env.oversea({ subspecs: ['overseas'] }, { subspecs: ['domestic'] })
      if_pod 'ZeroTrust', '0.4.11'
      if_pod 'LarkFocus', '0.1.21'
      if_pod 'MinutesMod', '5.6.0.5'
      if_pod 'LarkProfile', '0.0.107'
      if_pod 'Minutes', '5.6.0.7'
      if_pod 'MinutesFoundation', '5.6.0.4'
      if_pod 'MinutesInterface', '5.6.0.4'
      if_pod 'MinutesNavigator', '5.6.0.4'
      if_pod 'YYText', '1.0.24'
      if_pod 'LarkLiveMod', '5.6.0.1'
      if_pod 'LarkLive', '5.6.0.1'
      if_pod 'LarkLiveInterface', '5.6.0.1'
      if_pod 'UGReachSDK', '0.1.1'
      if_pod 'UGContainer', '0.0.5'
      if_pod 'UGBanner', '0.0.43'
      if_pod 'UGBadge', '0.0.2'
      if_pod 'UGRCoreIntegration', '0.1.2'
      if_pod 'UGRule', '0.0.10'
      if_pod 'UGCoordinator', '0.0.7'
      if_pod 'UGSpotlight', '0.0.11'
      if_pod 'AAFastbotTweak', '0.3.20'
      if_pod 'LarkRichTextCore', '5.5.0.3'
      if_pod 'LarkKeyboardView', '5.6.0.1'
    end

    def lark_pods
      if_pod 'oc-opus-codec', '0.2.7'
      if_pod 'LKCommonsLogging', '0.4.18'
      if_pod 'LKCommonsTracker', '0.4.16'
      if_pod 'AnimatedTabBar', '0.26.82'
      if_pod 'Sodium', '0.8.0-dolphin.1'
      if_pod 'RxAutomaton', '0.4.0'
      if_pod 'Homeric', '0.2.921'
      if_pod 'LKMetric', '0.23.2'
      if_pod 'LKTracing', '0.19.1'
      if_pod 'LarkTracing', '0.0.14'
      if_pod 'LarkCrashSanitizer', '3.41.33'
    end

    def lark_flutterPods
      if_pod 'BDFlutterPluginManager', '0.1.7'
      if_pod 'FlutterChannelTool', '2.0.0'
      if_pod 'TransBridge-iOS', '0.1.8'
      if_pod 'LarkMeego', '5.1.0.1'
      if_pod 'LarkMeegoInterface', :pods => ['LarkMeego']
      if_pod 'LarkMeegoInterface', '5.1.0.1'
      if_pod 'LarkMeego', :pods => ['LarkFlutterContainer']
      if_pod 'LarkFlutterContainer', '0.0.64-nullSafety', modular_headers: true
    end

    def lark_universeDesignPods
      if_pod 'UniverseDesignActionPanel', '2.0.18'
      if_pod 'UniverseDesignAvatar', '2.0.0'
      if_pod 'UniverseDesignBadge', '2.0.0'
      if_pod 'UniverseDesignBreadcrumb', '2.0.1'
      if_pod 'UniverseDesignButton', '2.0.0'
      if_pod 'UniverseDesignColor', '2.0.2'
      if_pod 'UniverseDesignCheckBox', '2.0.0'
      if_pod 'UniverseDesignDatePicker', '2.0.3'
      if_pod 'UniverseDesignDialog', '2.0.5'
      if_pod 'UniverseDesignDrawer', '2.0.0'
      if_pod 'UniverseDesignEmpty', '2.0.2'
      if_pod 'UniverseDesignFont', '2.0.0'
      if_pod 'UniverseDesignIcon', '2.1.18'
      if_pod 'UniverseDesignMenu', '2.0.4'
      if_pod 'UniverseDesignNotice', '2.0.1'
      if_pod 'UniverseDesignPopover', '2.0.0'
      if_pod 'UniverseDesignStyle', '2.0.0'
      if_pod 'UniverseDesignTabs', '2.0.16'
      if_pod 'UniverseDesignTag', '2.0.1'
      if_pod 'UniverseDesignTheme', '2.0.0'
      if_pod 'UniverseDesignToast', '2.0.5'
      if_pod 'UniverseDesignLoading', '2.0.0'
      if_pod 'UniverseDesignProgressView', '2.0.0'
      if_pod 'UniverseDesignSwitch', '2.0.1'
      if_pod 'UniverseDesignInput', '2.0.4'
      if_pod 'UniverseDesignColorPicker', '2.0.2'
      if_pod 'UniverseDesignCardHeader', '2.0.2'
      if_pod 'UniverseDesignShadow', '2.0.1'
    end

    def lark_commonPods
      if_pod 'AMapSearch-NO-IDFA', '7.3.0'
      if_pod 'LarkDeepLink', '0.0.10'
      if_pod 'BDCodeCoverageCollectTool', '0.1.3-alpha.0-lark.1.binary', source: 'git@code.byted.org:iOS_Library/toutiao_binary_repo.git'
      if_pod 'LarkCodeCoverage', '0.0.2'
      if_pod 'CodeCoverageTool', '0.7.0.1-bugfix'
      if_pod 'LarkOfflineCodeCoverage', '0.0.4'
      if_pod 'LarkSwipeCellKit', '0.22.5'
      if_pod 'Kingfisher', '5.3.1-lark.22'
      if_pod 'KingfisherWebP', '0.6.0-lark.0'
      if_pod 'Swinject', '10.15.7'
      if_pod 'LarkContainer', '1.18.5'
      if_pod 'LarkGuide', '3.12.33'
      if_pod 'LarkGuideUI', '0.14.45'
      if_pod 'LarkFoundation', '1.7.7'
      if_pod 'LarkUIKit', '100.15.120'
      if_pod 'LarkAssetsBrowser', '0.5.24'
      if_pod 'LarkImageEditor', '0.3.87', subspecs: %w[V1 V2]
      if_pod 'LarkRustClient', '3.42.27'
      if_pod 'LarkRustClientAssembly', '3.45.41'
      if_pod 'LarkAssembler', '0.0.2'
      if_pod 'Logger', '1.4.19', subspecs: %w[Core Lark]
      if_pod 'LKContentFix', '0.7.4'
      if_pod 'LarkFeatureGating', '3.44.38', inhibit_warnings: false, subspecs: %w[Core LarkAssemble]
      if_pod 'LarkFeatureSwitch', '3.41.8', inhibit_warnings: false
      if_pod 'LarkTraitCollection', '0.15.4', inhibit_warnings: false
      if_pod 'LarkModel', '100.14.78', inhibit_warnings: false
      if_pod 'EENavigator', '0.10.56'
      if_pod 'LarkTTNetInitializor', '0.0.32'
      if_pod 'ServerPB', '1.0.1586'
      if_pod 'SuiteAppConfig', '0.20.11', subspecs: %w[Core Assembly], inhibit_warnings: false
      if_pod 'SuiteCodable', '0.1.4'
      if_pod 'LarkTag', '0.24.44'
      if_pod 'AppContainer', '0.23.34'
      if_pod 'LarkSafeMode', '0.9.19'
      if_pod 'BootManager', '0.13.51'
      if_pod 'BootManagerConfig', '0.0.64'
      if_pod 'LKLoadable', '0.0.4'
      if_pod 'LarkSceneManager', '0.1.38', subspecs: %w[Core Extensions]
      if_pod 'LarkColor', '0.25.3'
      if_pod 'LarkCamera', '0.22.22'
      if_pod 'LarkCanvas', '2.0.35'
      if_pod 'LarkBlur', '0.1.8'
      if_pod 'LarkEmotion', '0.23.37', subspecs: %w[Core Assemble]
      if_pod 'EENotification', '0.23.3'
      if_pod 'NotificationUserInfo', '0.23.5'
      if_pod 'LarkCompatible', '0.1.1'
      if_pod 'LarkExtensions', '0.22.25'
      if_pod 'RoundedHUD', '1.21.26'
      if_pod 'LarkActionSheet', '0.24.21'
      if_pod 'EEFlexiable', '0.1.9'
      if_pod 'AsyncComponent', '0.1.55'
      if_pod 'LKRichView', '0.1.50'
      if_pod 'TangramComponent', '0.2.22'
      if_pod 'TangramLayoutKit', '0.1.19'
      if_pod 'TangramUIComponent', '0.1.42'
      if_pod 'TangramService', '0.0.31'
      if_pod 'TangramUIComponent', '0.1.42'
      if_pod 'LarkPageController', '0.22.4'
      if_pod 'EditTextView', '0.22.30'
      if_pod 'LarkAudioKit', '0.22.15'
      if_pod 'LarkAudioView', '0.22.23'
      if_pod 'EETroubleKiller', '1.2.8'
      if_pod 'EEKeyValue', '0.2.11', subspecs: %w[Core UserDefaults UserSpace]
      if_pod 'RxDataSources', '4.0.1'
      if_pod 'Action', '4.0.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'NSObject+Rx', '5.0.0'
      if_pod 'LarkAlertController', '1.0.9'
      if_pod 'EEPodInfoDebugger', '0.0.5'
      if_pod 'RunloopTools', '0.22.7'
      if_pod 'LarkKeyboardKit', '0.21.7'
      if_pod 'LarkKeyCommandKit', '0.21.14', subspecs: %w[Core Extensions]
      if_pod 'LarkInteraction', '0.19.12'
      if_pod 'LarkOrientation', '0.21.3'
      if_pod 'LarkBGTaskScheduler', '1.15.1'
      if_pod 'LarkPushTokenUploader', '0.24.11'
      if_pod 'LarkMonitor', '1.19.19'
      if_pod 'LarkOpenTrace', '1.2.5'
      if_pod 'ThreadSafeDataStructure', '0.21.4'
      if_pod 'LarkTracker', '100.13.25', inhibit_warnings: false
      if_pod 'LarkAppLog', '3.41.9', inhibit_warnings: false
      if_pod 'EEAtomic', '0.1.6'
      if_pod 'LarkLeanMode', '0.22.12'
      if_pod 'LarkSnsShare', '2.9.35', **$lark_env.oversea({ subspecs: ['InternationalSnsShareDependency'] }, { subspecs: ['InternalSnsShareDependency'] })
      if_pod 'LarkShareToken', '0.19.8'
      if_pod 'LarkActivityIndicatorView', '1.21.1'
      if_pod 'LarkResource', '0.0.12'
      if_pod 'LarkUIExtension', '0.7.2'
      if_pod 'LarkAddressBookSelector', '0.17.14'
      if_pod 'LarkListItem', '0.12.35'
      if_pod 'LarkFileKit', '0.6.7'
      if_pod 'AllLoadCost', '0.4.1'
      if_pod 'AllStaticInitializerCost', '0.1.0'
      if_pod 'LarkOuterTest', :pods => ['IESOuterTest']
      if_pod 'IESOuterTest', '0.5.1', subspecs: %w[Common Hybrid PopupInstall CNDomain TestPackage]
      if_pod 'IESWebKit', '3.4.2', subspecs: %w[Core WebView]

      if_pod 'LarkMagic', '0.4.23'
      if_pod 'lottie-ios', '2.6.5'
      if_pod 'LarkShareContainer', '0.1.33'
      if_pod 'IESGeckoKit', '2.0.1-rc.2-applog', **$lark_env.oversea({ subspecs: ['Config/OS', 'Core'] }, { subspecs: ['Config/CN', 'Core', 'Downloader'] })
      if_pod 'LarkBaseService', '3.45.121', subspecs: ['Core'], inhibit_warnings: false

      if_pod 'LarkKAEMM', '4.10.16', subspecs: $lark_env.emm_subspecs

      if_pod 'LarkBytedCert', '0.1.20'
      if_pod 'LarkDynamicResource', '0.1.39'
      if_pod 'LarkExtensionServices', '0.0.11', subspecs: %w[Config Log Account]
      if_pod 'LarkExtensionAssembly', '0.0.10'
      if_pod 'LarkMinimumMode', '1.0.20'
      if_pod 'FigmaKit', '0.0.30'
      if_pod 'TTMacroManager', '1.0.3'
    end

    def lark_thirdPartyPods
      lark_pod_heimdallr
      if_pod 'Alamofire', '4.7.3'
      if_pod 'DateToolsSwift', '5.0.0'
      if_pod 'FMDB', '2.7.7'
      if_pod 'KeychainAccess', '3.1.2'
      if_pod 'JSONModel', '1.8.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'RxSwift', '5.1.1', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'RxCocoa', '5.1.1', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'SnapKit', '5.0.1', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'SSZipArchive', '2.2.2', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'ReachabilitySwift', '4.3.0'
      if_pod 'Yoga', '1.9.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'UIImageViewAlignedSwift', '0.6.0'
      if_pod 'SkeletonView', '1.4.1'
      if_pod 'CryptoSwift', '1.3.3'
      if_pod 'SwiftyJSON', '4.1.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'HandyJSON', '5.0.3-lark.1'
      if_pod 'MBProgressHUD', '1.1.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'ESPullToRefresh', '2.9.8'
      if_pod 'libPhoneNumber-iOS', '0.9.15'
      if_pod 'LarkSegmentedView', '5.15.6'
      if_pod 'libpng', '~> 1.6.35'
      if_pod 'LarkCombine', '0.0.10'
      if_pod 'LarkOpenCombine', '0.0.9'
      if_pod 'LarkOpenCombineDispatch', '0.0.7'
      if_pod 'LarkOpenCombineFoundation', '0.0.7'
      if_pod 'TTTopSignature', '0.0.6'
      if_pod 'gaia_lib_publish', '10.60.0.6-D.1.binary', subspecs: %w[gaia Math Thread]

      # Pods for google
      if_pod 'AppAuth', '1.4.0'
      if_pod 'GTMAppAuth', '1.1.0'
      if_pod 'GTMSessionFetcher', '1.5.0'

      lark_reactNativePods
    end

    def lark_reactNativePods
      react_pod_version = '0.61.2.3'
      # React-Core
      if_pod 'React-Core', react_pod_version, :subspecs => ['DevSupport', 'Default', 'RCTWebSocket']
      if_pod 'React-jsi', react_pod_version
      if_pod 'React-cxxreact', react_pod_version
      if_pod 'React-jsiexecutor', react_pod_version
      if_pod 'React-jsinspector', react_pod_version

      # React-Core turbo modules
      if_pod 'React-CoreModules', react_pod_version
      if_pod 'FBReactNativeSpec', react_pod_version
      if_pod 'RCTTypeSafety', react_pod_version
      if_pod 'FBLazyVector', react_pod_version
      if_pod 'React-RCTImage', react_pod_version
      if_pod 'RCTRequired', react_pod_version
      if_pod 'React-RCTNetwork', react_pod_version
    end

    def lark_debugPods

      if_pod 'LarkDebugExtensionPoint', :pods => ['LarkDebug/core']
      if_pod 'LarkDebug', '100.13.17', subspecs: ['core']
      if $lark_env.testable || $lark_env.is_binary_cache_job
        if_pod 'LarkDebug', subspecs: ['Flex']
      end
      if_pod 'LarkDebugExtensionPoint', '3.42.0', inhibit_warnings: false
      # pod 'TTMLeaksFinder', '2.1.7-alpha.3-forLarkTest'
      # pod 'FBRetainCycleDetector', '0.2.0-alpha.9-forlarktest'
      if_pod 'Reveal-SDK', '26'
      if_pod 'DebugRouter', '2.0.16.1-bugfix.1.binary'
      if_pod 'TTMLeaksFinder', '2.1.8-alpha.1-ForLarkTest'
      if_pod 'FBRetainCycleDetector', '0.2.0-alpha.16-ForLarkTest'
      if_pod 'FLEX', '4.5.0'
      if_pod 'ByteViewDebug', '5.4.0.3'
      # Gecko Debug 头文件存在编译问题，暂时屏蔽
      # pod 'IESGeckoKitDebug', '1.0.15', :subspecs => ['Core']
      if_pod 'SwiftLint', '0.40.3'
      if_pod 'PassportDebug', '5.21.0.1'
    end

    # 多媒体相关的 Pod，互相有依赖，升级时可能需要一起
    def lark_pod_media
      if_pod 'ByteRtcSDK', '5.5.6'

      # 实名 SDK
      if_pod 'byted_cert', '4.2.5-rc.12', subspecs: %w[jsbridge offline download crypto]
      if_pod 'arkcrypto-minigame-iOS', '0.1.6.5'

      # AI lib 提供的图像处理的库：扫码、人脸识别
      if_pod 'smash',
             '6.5.0.1-binary',
             subspecs: %w[
               private_utils
               qrcode
               action_liveness
               utils
               package
             ]
      if_pod 'mobilecv2', '1.8.6'
      # smash内部依赖espresso
      if_pod 'espresso', '2.7.23'
    end

    def lark_pod_video_editor
      # 视频转码、压缩相关
      # Video transcode
      if_pod 'TTVideoEditor',
             '9.9.0.105-feishu-larkupdate-alpha.41.1.binary',
             subspecs: %w[LarkMode TTVEImage],
             source: 'git@code.byted.org:iOS_Library/privatethird_binary_repo.git'
      if_pod 'IESAppLogger_iOS',
             '0.0.22.1-binary',
             subspecs: ['OCInterface'],
             source: 'git@code.byted.org:iOS_Library/privatethird_binary_repo.git'
    end

    def lark_pod_heimdallr
      if_pod 'BDALog', '0.3.2-alpha.0.1.binary'
      if_pod 'MemoryGraphCapture', '1.3.5'
      if_pod 'BDFishhook', '~>0.1.1'
      if_pod 'AWECloudCommand', '1.3.3'

      $Heimdallr_subspecs = [
        'Protect',
        'Monitors',
        'TTMonitor',
        'HMDStart',
        'HMDANR',
        'UITracker',
        'HMDWatchDog',
        'CrashDetector',
        'UserException',
        'HMDOOMCrash',
        'HMDOOM',
        'MemoryGraph',
        'UIFrozen',
        'WatchdogProtect',
        'ALog',
        'Zombie',
        'HMDCoreDump',
        'CPUException',
        'ProtectCustomCatch',
        'HMDMetricKit',
        'CloudCommand',
        'TTNet',
        'NetworkTraffic',
        'HMDFDMonitor',
        'Dart',
        'GWPASan',
        'HMDSlardarMalloc',
        $lark_env.oversea('HMDOverseas', 'HMDDomestic')
      ]
      # bytest专属，线下APM
      $Heimdallr_subspecs.append('Offline') if $lark_env.bytest_package
      if_pod 'Heimdallr', '0.8.2-rc.2',
          source: 'git@code.byted.org:iOS_Library/privatethird_source_repo.git',
          subspecs: $Heimdallr_subspecs
      if_pod 'Heimdallr/HMDSlardarMalloc', :pods => ['SlardarMalloc']
      if_pod 'Heimdallr/GWPASan', :pods => ['HMDGWPASan']
      if_pod 'SlardarMalloc', '0.0.2.1-binary'
      if_pod 'HMDGWPASan', '0.0.3.1-binary'
    end

    def lark_pod_cjpay
      return if $lark_env.is_oversea # 海外版本不需要引入 cjpay
      if_pod 'CJPay', '6.0.4-feishu.3-bugfix', subspecs: [
        'PayBiz',
        'UserCenter',
        'BDPay',
        'VerifyModules/VerifyModulesBase',
        'VerifyModules/Biopayment',
        'Extensions',
        'Resource',
        'PayWebView',
        'PayCore/Base'
      ]
      if_pod 'CJPayDebugTools', '0.0.0.17', subspecs: [
        'EnvSwitch',
        'EnvConfig/BaseEnvConfig',
        'EnvConfig/WebviewEnvConfig',
        'EnvConfig/PayManageEnvConfig'
      ]
      if_pod 'tfccsdk', '2.0.8', subspecs: ['tfccsm']
    end

    def lark_pod_bullet
      bullet_version = '1.4.7-alpha.30.1-binary'
      if_pod 'BDXServiceCenter', bullet_version
      if_pod 'BDXLynxKit', bullet_version
      if_pod 'BDXMonitor', bullet_version
      if_pod 'BDXResourceLoader', bullet_version
      if_pod 'BulletX', bullet_version
      if_pod 'BDXOptimize', bullet_version
      if_pod 'BDXContainer', bullet_version
      if_pod 'BDXRouter', bullet_version
      if_pod 'BDXSchema', bullet_version

      if_pod 'TTNetworkDownloader', '1.1.22.1-binary'
      if_pod 'IESWebViewMonitor', '1.3.16.1-binary', subspecs: %w[Core CustomInterface Lynx HybridMonitor SettingModel]
      if_pod 'BDJSBridgeAuthManager', '1.4.2.1-binary', :subspecs => ['Rename']
      if_pod 'BDXBridgeKit', '2.6.3-rc.8', :subspecs => ['Methods/Info', 'Methods/Route', 'Methods/Storage', 'Methods/Log', 'Methods/Event', 'Methods/UI', 'Methods/Media', 'Methods/Network']
      if_pod 'BDUGLoggerInterface', '1.0.3'
      if_pod 'BDUGLoggerInterface', :pods => ['BDUGLogger']
      if_pod 'BDUGLogger', '1.1.5'
    end

    def lark_toutiaoPods
      lark_pod_video_editor
      lark_pod_media
      lark_pod_cjpay

      if_pod 'BDDataDecorator', '2.0.1.1-binary', subspecs: ['Data']
      if_pod 'BDDataDecoratorTob', '1.0.4', subspecs: ['Data'], source: 'git@code.byted.org:iOS_Library/privatethird_source_repo.git'

      if $lark_env.is_oversea
        if_pod 'TTVideoEngine', '1.10.56.10-lark', subspecs: %w[SG TraceReport] # （点播SDK）
      else
        if_pod 'TTVideoEngine', '1.10.56.10-lark', subspecs: %w[CN TraceReport] # （点播SDK）
      end
      if_pod 'ABRInterface', '2.1.1' # （ABR接口组件）
      if_pod 'TTNetworkPredict', '0.4.0', subspecs: ['algorithms', 'bridge', 'common', 'public']
      if_pod 'VCPreloadStrategy', ' 1.60.1-alpha.0.1.binary' # （预加载组件）
      if_pod 'VCVodSettings', '0.2.0.1-binary'

      if_pod 'TTVideoLive', '1.4.93.2' # (拉流SDK)

      if_pod 'TTPlayerSDK', '2.10.56.62-lark' # （播放SDK）
      if_pod 'audiosdk', '11.2.10-common.1.binary'
      if_pod 'TTFFmpeg', '1.25.56.12-lark' # （支持mp3、mjepg）
      if_pod 'lib_h_dec', '1.4.8'
      if_pod 'VCBaseKit', '0.5.1'
      if $lark_env.is_oversea # 国外版
        if_pod 'boringssl', '0.1.4'
      else
        if_pod 'boringssl', '0.1.5-alpha.10-SMOnline' # （ssl升级版）
      end
      if_pod 'MDLMediaDataLoader', '1.1.56.21' # （数据模块）
      if_pod 'VCNVCloudNetwork', '3.2.6' # （内部网络库，数据模块+上传需要一起升级）

      if_pod 'TTReachability', '1.8.6'
      if_pod 'TTNetworkManager', '4.0.78.3-tudp'

      if_pod 'SAMKeychain', '1.5.2.1-binary'

      if_pod 'RangersAppLog', '6.3.1', subspecs: %w[Core ET Filter]
      if_pod 'OneKit', '1.1.30', subspecs: %w[BaseKit Reachability StartUp Service]
      if_pod 'BDWebImage', '1.7.14',
             subspecs: %w[Core Download Decoder]
      if_pod 'libwebp', '0.6.1.1-binary'
      if_pod 'YYCache', '4.11.1'
      if_pod 'BDUGLogger', '1.1.5'
      unless $lark_env.is_oversea # 非国外版
        if_pod 'BDUGShare', '2.1.2-rc.3', subspecs: [
          'BDUGShareBasic/BDUGUtil',
          'BDUGShareBasic/BDUGWeChatShare',
          'BDUGShareBasic/BDUGWeiboShare',
          'BDUGShareBasic/BDUGQQShare'
        ]
        if_pod 'WechatSDK', '0.3.3', source: 'git@code.byted.org:iOS_Library/privatethird_source_repo.git'
        if_pod 'WeiboSDK', '3.2.5-rc.1'
        if_pod 'TencentQQSDK', '1.1.0-rc.0.1.binary'
        if_pod 'BDUGDeepLink', '1.9.4', subspecs: %w[DeepLink ASA]
        if_pod 'BDUGSecure', '0.3.0.1-bugfix'
      end
      if_pod 'ByteDanceKit', '3.3.9.1-bugfix'
      if_pod 'BDABTestSDK', '1.0.2'
      if_pod 'IESJSBridgeCore', '2.1.0'
      if_pod 'TTBridgeUnify', '5.2.4.1.binary', subspecs: %w[
        TTBridge
        UnifiedWebView
        TTBridgeAuthManager
      ]
      if_pod 'BDWebKit', '1.3.0.1-bugfix.1.binary', subspecs: %w[SecureLink Core]
      if_pod 'Gaia', '3.1.5'
      if_pod 'BDAssert', '2.0.0'
      if_pod 'BDMonitorProtocol', '1.1.1'
      if_pod 'BDWebCore', '2.1.2'
      if_pod 'ADFeelGood', '2.1.15-alpha.2'
      if_pod 'CookieManager', '0.2.24'
      if_pod 'LarkOpenChat', '0.1.22'
      if_pod 'TSPrivacyKit', '0.2.0.25.1-binary'
    end
  end
end
# rubocop:enable Layout/LineLength, Metrics/MethodLength
