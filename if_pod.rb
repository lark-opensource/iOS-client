# coding: utf-8
# frozen_string_literal: true

require 'lark/project/if_pod_helper'

# rubocop:disable Layout/LineLength, Metrics/MethodLength
module Pod
  # if_pod相关功能介绍文档：https://bytedance.feishu.cn/wiki/wikcnshvOC5W18wpz5yxJGVL2Mf
  # 这个文件里存放所有的版本限制，和可选集成依赖
  # 这个文件里的配置，可以被Podfile的配置覆盖
  # 这里面如果定义方法，需要使用lark_的前缀，避免子仓命名冲突
  # 这个文件里写入的限制和关联，可以同步给子仓复用
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
      if_pod 'LarkMicroApp', '5.31.0.5478545', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'LarkTabMicroApp', '5.31.0.5463996', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'LarkAppLinkSDK', '5.31.0.5463996', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'EEMicroAppSDK', '5.31.0.5480923', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'TTMicroApp', '5.31.0.5465229', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'SocketRocket', :source => 'git@code.byted.org:ee/pods_specs.git' # 这里发现 TTMicroApp 依赖了 SocketRocket, 默认是用的是Github的代码，bit会有兼容问题
      if_pod 'LarkOPInterface', '5.31.0.5463996', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPSDK', '5.31.0.5456909', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPGadget', '5.31.0.5456909', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPFoundation', '5.31.0.5456849', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPPlugin', '5.31.0.5454779', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPPluginBiz', '1.0.0', :inhibit_warnings => false
      if_pod 'OPPluginManagerAdapter', '1.0.0', :inhibit_warnings => false
      if_pod 'NewLarkDynamic', '5.31.0.5456309', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      # Block
      if_pod 'Blockit', '5.31.0.5463996', :inhibit_warnings => false
      if_pod 'OPBlock', '5.31.0.5463996', :inhibit_warnings => false
      if_pod 'OPBlockInterface', '5.31.0.5483135', :inhibit_warnings => false
      if_pod 'LarkBlockHost', '0.0.1', :inhibit_warnings => false
      if_pod 'BlockMod', '0.0.1', :inhibit_warnings => false
      # LarkWorkplace
      if_pod 'LarkWorkplace', '5.31.0.5461589', :inhibit_warnings => false
      if_pod 'LarkWorkplaceModel', '5.31.0.5463996', :inhibit_warnings => false
      if_pod 'LarkOpenWorkplace', '0.0.1', :inhibit_warnings => false
      if_pod 'WorkplaceMod', '5.29.0.1', :inhibit_warnings => false
      # ECOInfra
      if_pod 'ECOInfra', '5.31.0.5456849', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'ECOProbe', '5.31.0.5463996', :inhibit_warnings => false # 请不要手动修改生态系统Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'ECOProbeMeta', '5.31.0.5482304' # 「OPMonitor埋点代码生成工具」根据「OPMonitor埋点元数据」生成的「OPMonitor埋点代码」仓库
      # OpenAPI
      if_pod 'LarkOpenPluginManager', '5.31.0.5476679', :inhibit_warnings => false # 开放API Pod，请不要手动修改开放API Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'LarkOpenAPIModel', '5.31.0.5454779', :inhibit_warnings => false # 开放API Pod，请不要手动修改开放API Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      # web pods
      if_pod 'LarkWebViewContainer', '5.31.0.5463996', :inhibit_warnings => false # 套件统一WebView，请不要手动修改套件统一WebViewPod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'WebBrowser', '5.31.0.5454293', :inhibit_warnings => false # 套件统一浏览器，请不要手动修改套件统一浏览器Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'EcosystemWeb', '5.31.0.5474886', :inhibit_warnings => false # Ecosystem Client Native Web Business，请不要手动修改EcosystemWeb Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'OPWebApp', '5.31.0.5463996', :inhibit_warnings => false #套件统一WebView，请不要手动修改套件统一WebViewPod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      #动态组件【小程序插件】
      if_pod 'OPDynamicComponent', '5.31.0.5463996', :inhibit_warnings => false #套件统一WebView，请不要手动修改套件统一WebViewPod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'LarkLynxKit', '0.0.1', :inhibit_warnings => false
      if_pod 'LarkMessageCard', '5.31.0.5465229', :inhibit_warnings => false
      # 生态系统仓库 end
      # web functional pods
      if_pod 'LarkWebviewNativeComponent', '5.30.0.1', :inhibit_warnings => false # 套件统一WebView同层渲染
      if_pod 'LarkWebCache', '3.41.11'
      # 服务台/oncall/HelpDesk
      if_pod 'HelpDesk', '5.31.0.5463996', :inhibit_warnings => false # HelpDesk，请不要手动修改 HelpDesk Pod的版本号，必须使用bits多仓MR集成功能，如果手工修改导致事故，需要revert代码，写case study，做复盘，承担事故责任
      if_pod 'LarkJSEngine', '5.31.0.5463996', :inhibit_warnings => false
      if_pod 'OPJSEngine', '5.31.0.5463996', :inhibit_warnings => false

      # 补充没被写到 if_pod 中的本地模块
      if_pod 'JsSDK', '5.30.0.1', :inhibit_warnings => false
      if_pod 'LarkAppStateSDK', '5.29.0.1', :inhibit_warnings => false

      if_pod 'UniversalCardInterface', ''
      if_pod 'UniversalCardBase', ''
      if_pod 'UniversalCard', ''
    end

    def lark_larkMessengerPods
      # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能，相关文档：https://bytedance.feishu.cn/wiki/wikcnJzs27QgWQippNuElSOey9c
      if_pod 'MessengerMod', '5.31.0.5424672'
      if_pod 'LarkAttachmentUploader', '5.28.0.5328835' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能 # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFeed', '5.32.0.5486858' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFeedEvent', '5.30.0.5410491' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFeedBanner', '5.30.0.5415335' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFeedPlugin', '5.32.0.5485092' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkOpenFeed', '0.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFeedBase', '0.0.1' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkMine', '5.31.0.5474091' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkUrgent', '5.30.0.5410491', **$lark_env.feature($lark_env.is_em_enable, {
        subspecs: ['Core', 'EMC', 'EMD']
      }, {
        subspecs: ['Core', 'EMC']
      }) # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFinance', '5.30.0.5434208', **$lark_env.oversea({ subspecs: ['Core'] }, { subspecs: %w[Core Pay] }) # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkChat', '5.32.0.5485092' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkChatSetting', '5.31.0.5477737' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkFile', '5.31.0.5424672' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkThread', '5.31.0.5470696' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkContact', '5.32.0.5485028', **$lark_env.oversea({ subspecs: %w[Core UGOversea] }, { subspecs: ['Core'] }) # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSearch', '5.32.0.5477259' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSearchCore', '5.32.0.5486858' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkAI', '5.31.0.5464178' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkMessageCore', '5.31.0.5470696' # , :testspecs => ['Tests']  # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSearchFilter', '5.30.0.5403035' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkForward', '5.31.0.5465501' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkAudio', '5.31.0.5477343' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkCore', '5.32.0.5483844' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkQRCode', '5.31.0.5470752' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkMessengerInterface', '5.32.0.5485092' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSDK', '5.32.0.5485092' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSendMessage', '5.32.0.5486875' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkSDKInterface', '5.32.0.5485092' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'Moment', '5.31.0.5464556' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkTeam', '5.31.0.5434244' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'DynamicURLComponent', '5.31.0.5479096' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkBaseKeyboard', '0.0.1', subspecs: ["Transformers", "InputHanders", "VociePanel", "AtPanel", "CanvasPanel", "EmojiPanel", "FontPanel", "ImageAttachment", "Keyboard", "MorePanel", "OtherPanel", "PicturePanel", "Resources", "Tool"]
      if_pod 'LarkOpenKeyboard', '0.1.0-alpha.0' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkChatOpenKeyboard', '0.1.0-alpha.0' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
      if_pod 'LarkChatKeyboardInterface', '0.1.0-alpha.0' # 请不要手动修改Messenger业务库的版本号，使用bits多仓MR集成功能
    end

    def lark_spacekitPods
      if_pod 'CCMMod', '5.31.0.5484102' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKResource', '5.31.0.5484203' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKFoundation', '5.31.0.5341924' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKUIKit', '5.31.0.5484102' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKCommon', '5.31.0.5484102' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKBrowser', '5.31.0.5341924' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKDoc', '5.31.0.5484102' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKSheet', '5.31.0.5341924' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKBitable', '5.31.0.5341924' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKMindnote', '5.27.0.1' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKWikiV2', '5.31.0.5341924' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SpaceKit', '5.31.0.5341924' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SpaceInterface', '5.31.0.5424672' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKSpace', '5.31.0.5341924' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKDrive', '5.31.0.5341924' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKComment', '0.0.0.1' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKInfra', '0.0.0.1' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKSlides', '0.0.0.1' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKPermission', '0.0.0.1' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'SKWorkspace', '0.0.0.1' # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能
      if_pod 'WebAppContainer', '0.0.0.1'  # 请不要手动修改SpaceKit业务库的版本号，使用bits多仓MR集成功能

      if_pod 'SQLiteMigrationManager.swift', '0.8.0'
      if_pod 'SQLite.swift', '0.13.0'
      if_pod 'LibArchiveKit', '5.31.0.5463996'
    end

    def lark_calendarPods
      if_pod 'CalendarMod', '5.31.0.5464556'
      if_pod 'Calendar', '5.31.0.5459212' # 请不要手动修改calendarPods业务库的版本号，使用bits多仓MR集成功能
      if_pod 'CalendarFoundation', '5.29.0.1' # 请不要手动修改calendarPods业务库的版本号，使用bits多仓MR集成功能
      if_pod 'CalendarRichTextEditor', '5.29.0.1' # 请不要手动修改calendarPods业务库的版本号，使用bits多仓MR集成功能
      if_pod 'TodoMod', '5.31.0.5453726'
      if_pod 'Todo', '5.31.0.5484435' # 请不要手动修改lark_calendarPods业务库的版本号，使用bits多仓MR集>成功能
      if_pod 'TodoInterface', '5.31.0.5453726' # 请不要手动修改lark_calendarPods业务库的版本号，使用bits多仓MR集成功能
      if_pod 'CTFoundation', '5.31.0.5453726' # 请不要手动修改lark_calendarPods业务库的版本号，使用bits多仓MR集成功能
    end

    def lark_byteviewPods
        nfdsdk_lto_version, nfdsdk_nolto_version = lto_module_version("2.2.0-lark", :nfdsdk)
        if_pod 'nfdsdk', $lark_env.use_module_nolto(nfdsdk_nolto_version, nfdsdk_lto_version) # nfdsdk为lto开启组件，为了减少开发链接过程中的lto再编译时间，更新nfdsdk的时候请参考lto_module_version更新它的非lto版本
        if_pod 'ByteViewMod', '5.31.0.5477762'
        if_pod 'ByteViewInterface', '5.31.0.5463996'
        if_pod 'ByteViewCalendar', '6.1.0.1'
        if_pod 'ByteViewRTCRenderer', '5.31.0.5474100'
        if_pod 'ByteViewUDColor', '5.25.0.1'
        if_pod 'ByteViewMessenger', '5.31.0.5464556'
        if_pod 'ByteViewCommon', '5.31.0.5463996'
        if_pod 'ByteViewTracker', '5.31.0.5477762'
        if_pod 'ByteViewUI', '5.31.0.5463996'
        if_pod 'ByteViewNetwork', '5.31.0.5452138'
        if_pod 'ByteViewTab', '5.31.0.5477058'
        if_pod 'Whiteboard', '5.31.0.5463996'
        if_pod 'WbLib', '6.2.6'
        if_pod 'ByteViewMeeting', '5.31.0.5463996'
        if_pod 'ByteViewLiveCert', '6.0.0.1'
        if_pod 'ByteViewSetting', '6.0.0.1'
        if_pod 'ByteViewRtcBridge', '6.7.0.1'
        if_pod 'ByteViewHybrid', '5.31.0.5452138'
        if_pod 'ByteViewMeetingComponents', '5.19.0.1'
        if_pod 'ByteViewWidget', '0.1.0-alpha.0'
        if_pod 'ByteViewWidgetService', '0.1.0-alpha.0'

        if $lark_env.is_callkit_enable
            if_pod 'ByteViewMod', subspecs: ['CallKit']
        end
        if_pod 'ByteView', '5.32.0.5486886'
        if_pod 'LarkMedia', '7.1.0', **$lark_env.feature($lark_env.testable || $lark_env.is_binary_cache_job, {
          subspecs: %w[Core Hook Debug Rx Track API]
        }, {
          subspecs: %w[Core Hook Rx Track API]
        })
        if_pod 'LarkRVC', '5.31.0.5463996'

        if_pod 'LarkShortcut', '0.0.1', :pods => ['LarkShortcutAssembly']
        if_pod 'LarkShortcutAssembly', '0.0.1'
    end

    # Lark 定制版，如需更新请联系 Ecosystem, AI & Search, 钱包等业务
    def lark_pod_lynx
      lynx_version = '2.10.19-lark.1-bugfix'
      lynx_config = $lark_env.is_oversea ? 'BDConfig/OS' : 'BDConfig/CN'
      if_pod 'XElement', lynx_version, #:path => '/Users/renpengcheng/Desktop/workspace/douyinOncall/template-assembler',
      subspecs: %w[
        Swiper
        Input
        Picker
        Text
        ScrollView
        SVG
        Overlay
      ]
      if_pod 'Lynx', lynx_version,#:path => '/Users/renpengcheng/Desktop/workspace/douyinOncall/template-assembler',
      subspecs: %W[
        Framework
        Native
        JSRuntime
        ReleaseResource
        BDLynx
        LepusNG
        Inspector
        NapiBinding
        Krypton/Core
        #{lynx_config}
      ]
      if_pod 'Lynx', :pods => ['Napi']
      if_pod 'LarkAccountInterface', :pods => ['LarkAccount']
      if_pod 'LarkAccount', :pods => ['LarkAccountAssembly']
      if_pod 'LarkAccountAssembly', '5.31.0.5467269'
      if_pod 'LynxDevtool', lynx_version#:path => '/Users/renpengcheng/Desktop/workspace/douyinOncall/template-assembler'

      vmsdk_config = $lark_env.is_oversea ? 'monitor/overseas' : 'monitor/domestic'
      if_pod 'vmsdk', '2.2.7-lark', subspecs: %W[
        #{vmsdk_config}
        basic
        basic/log
        jsbridge
        lark_worker
        monitor/core
        napi
        napi/core
        napi/env
        napi/jsc
        napi/quickjs
        napi/v8
        quickjs
        quickjs_debugger
        umbrella
      ]

      # 固定HeliumEffectAdapterHeader的版本，否则会编译报错
      if_pod 'HeliumEffectAdapterHeader', '0.1.1'
    end

    def lark_businessPods
      lark_larkMessengerPods
      lark_spacekitPods
      lark_calendarPods
      lark_ecosystemAndWebAndWebFunctionalPods
      lark_byteviewPods

      if_pod 'ByteWebImage', '5.31.0.5470696', **$lark_env.feature($lark_env.testable || $lark_env.is_binary_cache_job, {
          subspecs: %w[LarkDebug]
        }, {
          subspecs: %w[Lark]
        })
      if_pod 'LarkWaterMark', '5.31.0.5463996'
      if_pod 'LarkAvatar', '5.31.0.5463166'
      if_pod 'MailSDK', '5.31.0.5483980' #:path => '../mail-ios-client/MailSDK',
      if_pod 'LarkMail', '5.31.0.5483980'
      if_pod 'LarkBizAvatar', '5.26.0.5275828'
      if_pod 'LarkAvatarComponent', '5.26.0.5262607'
      if_pod 'AvatarComponent', '5.26.0.5262607'
      if_pod 'LarkZoomable', '0.3.1'
      if_pod 'LarkMailInterface', '5.28.0.1'
      if_pod 'LarkBizTag', '5.30.0.5435278', :subspecs => [ 'Core', 'Chatter', 'PB', 'Messenger' ]
      if_pod 'EffectPlatformSDK', '2.9.158.1-bugfix', :subspecs => [ 'Core', 'ModelDistribute' ]
      if_pod 'EffectSDK_iOS', '14.5.0.275-LarkMobile.1.binary', :subspecs => [ 'Core', 'PartModel' ]
      if_pod 'EffectSDK_iOS', :pods => ['Napi']
      if_pod 'bytenn-ios', '3.4.81'
      if_pod 'AGFX_pub', '14.5.0.2.1.binary'
      if_pod 'VCInfra', '0.1.4'
      if_pod 'AppReciableSDK', '0.1.66'
      if_pod 'JTAppleCalendar', '7.1.7'
      if_pod 'LarkEditorJS','7.2.2'
      lark_pod_bullet
      lark_pod_lynx
      if_pod 'HTTProtocol', '5.31.0.5463996'
      if_pod 'LarkRustHTTP', '5.26.0.5262607'
      if_pod 'LarkAccountInterface', '5.31.0.5454235'
      if_pod 'LarkAccountInterface', :pods => ['LarkAccount']
      if_pod 'LarkNotificationContentExtension', 'placeholder_version'
      if_pod 'LarkHTTP', 'placeholder_version'
      if_pod 'LarkNotificationServiceExtensionLib', 'placeholder_version'

      # About is_ka_login_mode: $(git rev-parse --show-toplevel)/bin/lib/lark-project/lib/lark/project/environment.rb
      if_pod 'LarkAccount', '5.32.0.5482716', **$lark_env.feature($lark_env.is_ka_login_mode,
        $lark_env.ka_secsdk({
          subspecs: %w[Core Authorization IDP GoogleSignIn RustPlugin NativePlugin TuringCN KA BootManager SecSDKKA]
        }, {
          subspecs: %w[Core Authorization IDP GoogleSignIn RustPlugin NativePlugin TuringCN KA BootManager SecSDKPub]
        }), $lark_env.oversea({
          subspecs: %w[Core Authorization IDP GoogleSignIn RustPlugin NativePlugin TuringOversea BootManager SecSDKPub]
        }, $lark_env.isAutoLogin({
          subspecs: %w[Core Authorization IDP RustPlugin NativePlugin TuringCN OneKeyLogin BootManager SecSDKPub bytestAutoLogin]
        }, {
          subspecs: %w[Core Authorization IDP RustPlugin NativePlugin TuringCN OneKeyLogin BootManager SecSDKPub]
        })))

      if_pod 'LarkSecurityAudit', '5.31.0.5463996', subspecs: %w[Core Assembly Authorization]
      if_pod 'LarkAppConfig', '5.26.0.5257287'
      if_pod 'LarkEnv', '5.27.0.5286941'
      if_pod 'LarkKAFeatureSwitch', '5.27.0.5296228'
      if_pod 'LarkKAExpiredObserver', '5.30.0.5410491'
      if_pod 'LKJsApiExternal/Core', ''
      if_pod 'LKWebContainerExternal', ''
      if_pod 'LKPassportExternalAssembly', ''
      if_pod 'LKPassportExternal', ''
      if_pod 'NativeAppPublicKit', ''

      if $lark_env.is_ka?
      if_pod 'LarkKAEMM', '5.26.0.5252438', subspecs: %w[Core Custom]
      if_pod 'LKAppLinkExternalAssembly', '5.26.0.5262583'
      if_pod 'LKNativeAppExtensionAbility', '5.26.0.5262583'
      if_pod 'LKLifecycleExternalAssembly', '5.26.0.5262583'
      if_pod 'LKKeyValueExternalAssembly', '5.26.0.5262583'
      if_pod 'LKQRCodeExternal', '5.26.0.5262583'
      if_pod 'LKKeyValueExternal', '5.26.0.5262583'
      if_pod 'LKNativeAppExtension', '5.26.0.5262583'
      if_pod 'LKKACore', '5.26.0.5262583'
      if_pod 'LKAppLinkExternal', '5.26.0.5262583'
      if_pod 'LKQRCodeExternalAssembly', '5.26.0.5262583'
      if_pod 'LKNativeAppContainer', '5.26.0.5262583'
      if_pod 'LKTabExternal', ''
      if_pod 'LKStatisticsExternalAssembly', '', subspecs: %w[Core SM2]
      end
      if_pod 'LarkKAFKMS', '0.0.13'
      if_pod 'LarkKAAssembler', '5.26.0.5237940'
      if_pod 'LarkMessageBase', '5.31.0.5470696'
      if_pod 'LarkNavigation', '5.31.0.5461589', pods: ['LarkNavigationAssembly']
      if_pod 'LarkNavigationAssembly', '5.31.0.5461589'
      if_pod 'LarkNavigator', '3.38.15'
      if_pod 'LarkSplitViewController', '5.31.0.5463996'
      if_pod 'LarkPerf', '5.29.0.5406543'
      if_pod 'LarkAppResources', '5.26.0.5257287'
      if_pod 'LarkIllustrationResource', '5.26.0.5262607'
      if_pod 'LarkUniverseResource', '5.26.0.5262607'
      if_pod 'LarkWidgetService', '5.26.0.5262607'
      if_pod 'LarkButton', '0.22.6'
      if_pod 'LarkLocalizations', '5.31.0.5462438'
      if_pod 'icu_lark', '72.1.3'
      if_pod 'RichLabel', '5.31.0.5463996'
      if_pod 'LarkReleaseConfig', '5.29.0.5377785'
      if_pod 'QRCode', '5.31.0.5470752', :subspecs => ['Biz']
      if_pod 'LarkBadge', '5.26.0.5262607'
      if_pod 'LarkBadgeAssembly', '5.26.0.5262607'
      if_pod 'LarkBadge', :pods => ['LarkBadgeAssembly']
      if_pod 'LarkAccount', :pods => ['LarkLaunchGuide', 'LKLaunchGuide', 'LarkPrivacyAlert']
      if_pod 'LarkLaunchGuide', '5.30.0.5410491'
      if_pod 'LKLaunchGuide', '5.31.0.5450560'
      if_pod 'LarkPrivacyAlert', '5.31.0.5450560'
      if_pod 'LarkPrivacySetting', '5.30.0.5410491'
      if_pod 'LarkTourInterface', '5.31.0.5461589'
      if_pod 'LarkTourInterface', :pods => ['LarkTour']
      if_pod 'LarkTour', '5.31.0.5461589'
      if_pod 'LarkQuaterback', '5.26.0.5271879', **$lark_env.oversea({ subspecs: ['overseas'] }, { subspecs: ['domestic'] })
      if_pod 'Quaterback', '3.1.0-rc.3'
      if_pod 'LarkCustomerService', '5.26.0.5262607'
      if_pod 'LarkLocationPicker', '5.31.0.5465592', **$lark_env.oversea({ subspecs: ['OverSeaDependency'] }, { subspecs: ['InternalDependency'] })
      if_pod 'LarkReactionView', '5.30.0.5410491'
      if_pod 'LarkReactionDetailController', '5.31.0.5463996'
      if_pod 'LarkMenuController', '5.29.0.5408503'
      if_pod 'LarkSheetMenu', '0.1.0'
      if_pod 'LarkSafety', '5.26.0.5262607'
      if_pod 'LarkCoreLocation', '5.31.0.5465592', **$lark_env.oversea({ subspecs: ['InternationalImp'] }, { subspecs: ['InternalImp'] })
      if_pod 'LarkDatePickerView', '5.30.0.5410491'
      if_pod 'SelectMenu', '5.30.0.5410491'
      if_pod 'LarkTimeFormatUtils', '5.7.0.1'
      if_pod 'OfflineResourceManager', '5.31.0.5449536'
      if_pod 'EEImageMagick', '0.1.8'
      if_pod 'LarkSuspendable', '5.30.0.5410491'
      if_pod 'SecSDK', '1.6.2'
      if_pod 'LarkSettingsBundle', '5.26.0.5262607'
      if_pod 'LarkSetting', '5.31.0.5484102', subspecs: %w[Core LarkAssemble]
      if_pod 'LarkRustFG', '0.0.1'
      if_pod 'LarkBoxSetting', '0.0.1'
      if_pod 'LarkBoxSettingAssembly', '0.0.1'
      if_pod 'LarkVersion', '5.30.0.5410491', pods: ['LarkVersionAssembly']
 	  if_pod 'URLInterceptorManagerAssembly', '5.26.0.5262607'
      if_pod 'LarkVersionAssembly', '5.26.0.5257287'

      if_pod 'LarkCache', '5.30.0.5447138', subspecs: %w[Core CryptoRustImpl]
      if_pod 'LarkCacheAssembly', '5.29.0.5387566'
      if_pod 'LarkCache', :pods => ['LarkCacheAssembly']
      if_pod 'LarkTab', '0.2.15'
      if_pod 'LarkVote', '5.30.0.5410491'
      if_pod 'LarkFlag', '5.31.0.5470696'
      if_pod 'LarkEmotionKeyboard', '5.31.0.5475597'

      if_pod 'BDASplashSDKI18N', '1.14.0-rc.0', subspecs: ['Core']
      if_pod 'TTAdSplashSDK', '0.7.26.15-bugfix.1.binary', subspecs: ['Core']
      if_pod 'LarkSplash', '5.31.0.5475435', **$lark_env.oversea({ subspecs: ['overseas'] }, { subspecs: ['domestic'] })
      if_pod 'ZeroTrust', '5.30.0.5410491'
      if_pod 'LarkFocus', '5.32.0.5484880'
      if_pod 'LarkFocusInterface', '0.0.1'
      if_pod 'MinutesMod', '5.31.0.5475724'
      if_pod 'MinutesDependency', '0.1.1'
      if_pod 'LarkProfile', '5.31.0.5476399'
      if_pod 'Minutes', '5.31.0.5481521'
      if_pod 'MinutesFoundation', '5.31.0.5475724'
      if_pod 'MinutesNetwork', '0.1.2'
      if_pod 'MinutesInterface', '5.29.0.3'
      if_pod 'MinutesNavigator', '5.29.0.3'
      if_pod 'YYText', '1.0.26'
      if_pod 'LarkLiveMod', '5.31.0.5463996'
      if_pod 'LarkLive', '5.31.0.5463996'
      if_pod 'LarkLiveInterface', '5.20.0.2'
      if_pod 'UGReachSDK', '5.26.0.5262607'
      if_pod 'UGContainer', '5.31.0.5463996'
      if_pod 'UGBanner', '5.30.0.5362738'
      if_pod 'UGBadge', '5.26.0.5262607'
      if_pod 'UGDialog', '5.28.0.5342678'
      if_pod 'UGRCoreIntegration', '5.28.0.5342678'
      if_pod 'UGRule', '5.26.0.5262607'
      if_pod 'UGCoordinator', '5.28.0.5342678'
      if_pod 'UGSpotlight', '5.26.0.5262607'
      if_pod 'LarkDialogManager', '5.30.0.5416280'
      if_pod 'AAFastbotTweak', '0.3.20'
      if_pod 'LarkRichTextCore', '5.31.0.5471505'
      if_pod 'LarkKeyboardView', '5.31.0.5475597'
      if_pod 'LarkCloudScheme', '5.30.0.5410491'
      if_pod 'LarkOpenPlatform', '5.31.0.5454779', pods: %w[LarkOpenPlatformAssembly], subspecs: ['Core']
      if_pod 'LarkOpenPlatformAssembly', '5.31.0.5464556'
      if_pod 'LarkSecurityCompliance', 'placeholder_version', :pods => ($lark_env.testable || $lark_env.is_binary_cache_job) ? ['SecurityComplianceDebug'] : []
      if_pod 'SecurityComplianceDebug', '5.31.0.5474466'
      if_pod 'LarkSecurityComplianceInfra', '5.29.0.5387566'
      if_pod 'LarkSecurityComplianceInterface', '0.0.1', :pods => ['LarkSecurityCompliance']
      if_pod 'LarkEMM', '5.31.0.5472055'
      if_pod 'LarkPolicyEngine', '6.2.0.1'
      if_pod 'LarkExpressionEngine', '6.2.0.1'
      if_pod 'LarkSensitivityControl', '6.2.0.2', subspecs: ['Core', 'API/Location', 'API/Pasteboard', 'API/DeviceInfo', 'API/Camera', 'API/Calendar', 'API/AudioRecord', 'API/Contacts', 'API/Album', 'API/RTC']
      if_pod 'LarkSnCService', '6.2.0.1', subspecs: ['Core', 'Extensions/Bundle', 'Extensions/ConvenientTools']
      if_pod 'LarkMention', '5.30.0.5410491'
      if_pod 'LarkIMMention', '5.31.0.5456899'
      if_pod 'LarkPrivacyMonitor', '6.2.0.1', subspecs: ['Core']
      if_pod 'TSPrivacyKit', '0.4.0.49-lark'
      if_pod 'BDRuleEngine', '3.3.2.1-bugfix', subspecs: ['Core', 'Privacy']
      if_pod 'PNSServiceKit', '1.1.16'
      if_pod 'TTKitchen', '4.3.16'
      if_pod 'LarkContactComponent', '0.0.2'
      if_pod 'ShootsAPISocket', '0.0.2-alpha.0'
      if_pod 'LarkAIInfra', '0.0.1'
      if_pod 'LarkInlineAI', '0.0.1'
      if_pod 'LarkDocsIcon', '0.0.1'
      if_pod 'LarkIcon', '0.0.1'
      if_pod 'CTADialog', '0.0.1', **$lark_env.feature($lark_env.testable || $lark_env.is_binary_cache_job, {
        subspecs: %w[Core Debug]
      }, {
        subspecs: %w[Core]
      })
      if_pod 'LarkNotificationAssembly', '0.0.1', **$lark_env.feature($lark_env.testable || $lark_env.is_binary_cache_job, {
        subspecs: %w[Core Debug]
      }, {
        subspecs: %w[Core]
      })
    end

    def lark_pods
      if_pod 'oc-opus-codec', '0.2.9-module'
      if_pod 'LKCommonsLogging', '5.30.0.5405807'
      if_pod 'LKCommonsTracker', '5.27.0.5300226'
      if_pod 'AnimatedTabBar', '5.30.0.5410491'
      if_pod 'RxAutomaton', '0.4.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'Homeric', '0.2.1170'
      if_pod 'LKMetric', '5.26.0.5257287'
      if_pod 'LKTracing', '5.26.0.5257287'
      if_pod 'LarkTracing', '5.26.0.5262607'
      if_pod 'LarkCrashSanitizer', '5.26.0.5257287'
      if_pod 'LarkTraceId', '0.0.2'
      if_pod 'MailNativeTemplate', '7.10.0-20231227142936'
    end

    def lark_flutterPods
      if_pod 'BDFlutterPluginManager', '0.1.7'
      if_pod 'FlutterChannelTool', '2.0.0'
      if_pod 'TransBridge-iOS', '0.1.8'
      if_pod 'LarkMeegoInterface', '7.8.0.1'
      if_pod 'LarkMeego', '7.9.0.2', **$lark_env.feature($lark_env.testable || $lark_env.is_binary_cache_job, {
        subspecs: %w[Core Debug]
      }, {
        subspecs: %w[Core]
      })
      if_pod 'LarkFlutterContainer', '7.9.1', modular_headers: true, **$lark_env.oversea({ subspecs: %w[Interface Core Overseas] }, { subspecs: %w[Interface Core Domestic] })
      if_pod 'MeegoMod', '7.9.0.1', :pods => [
        'LarkMeegoInterface',
        'LarkMeego',
        'LarkFlutterContainer',
        'meego_rust_ios',
        'LarkMeegoPush',
        'LarkMeegoNetClient',
        'LarkMeegoLogger',
        'LarkMeegoStorage',
        'LarkMeegoStrategy',
        'LarkMeegoWorkItemBiz',
        'LarkMeegoViewBiz',
        'LarkMeegoProjectBiz'
      ]
      if_pod 'LarkMeegoPush', '7.5.0.1'
      if_pod 'LarkMeegoNetClient', '7.5.0.2'
      if_pod 'meego_rust_ios', '0.0.21', :subspecs => ["Core"]
      if_pod 'LarkMeegoLogger', '6.4.0.1'
      if_pod 'LarkMeegoStorage', '6.4.0.1'
      if_pod 'LarkMeegoStrategy', '7.7.0.1'
      if_pod 'LarkMeegoWorkItemBiz', '6.5.0.1'
      if_pod 'LarkMeegoViewBiz', '7.9.0.1'
      if_pod 'LarkMeegoProjectBiz', '6.4.0.1'
    end

    def lark_universeDesignPods
      if_pod 'UniverseDesignActionPanel', '5.30.0.5426199'
      if_pod 'UniverseDesignAvatar', '5.30.0.5426199'
      if_pod 'UniverseDesignBadge', '5.30.0.5426199'
      if_pod 'UniverseDesignBreadcrumb', '5.30.0.5426199'
      if_pod 'UniverseDesignButton', '5.30.0.5426199'
      if_pod 'UniverseDesignColor', '5.30.0.5426199'
      if_pod 'UniverseDesignCheckBox', '5.30.0.5426199'
      if_pod 'UniverseDesignDatePicker', '5.30.0.5410491'
      if_pod 'UniverseDesignDialog', '5.30.0.5426199'
      if_pod 'UniverseDesignDrawer', '5.30.0.5426199'
      if_pod 'UniverseDesignEmpty', '5.30.0.5426199'
      if_pod 'UniverseDesignFont', '2.0.1'
      if_pod 'UniverseDesignIcon', '3.0.1'
      if_pod 'UniverseDesignMenu', '2.1.11'
      if_pod 'UniverseDesignNotice', '5.30.0.5437071'
      if_pod 'UniverseDesignPopover', '2.0.3'
      if_pod 'UniverseDesignStyle', '2.0.0'
      if_pod 'UniverseDesignTabs', '2.0.23'
      if_pod 'UniverseDesignTag', '5.30.0.5437658'
      if_pod 'UniverseDesignTheme', '2.0.10'
      if_pod 'UniverseDesignToast', '5.30.0.5442158'
      if_pod 'UniverseDesignLoading', '2.0.6'
      if_pod 'UniverseDesignProgressView', '2.0.0'
      if_pod 'UniverseDesignSwitch', '2.0.2'
      if_pod 'UniverseDesignInput', '2.0.9'
      if_pod 'UniverseDesignColorPicker', '5.30.0.5426199'
      if_pod 'UniverseDesignCardHeader', '5.30.0.5426199'
      if_pod 'UniverseDesignShadow', '2.0.3'
      if_pod 'UDDebug', :path => '0.0.1'
    end

    def lark_commonPods
      if_pod 'AMapSearch-NO-IDFA', '8.1.0'
      if_pod 'AMap3DMap-NO-IDFA', '8.1.0'
      if_pod 'BDCodeCoverageCollectTool', '0.1.3-alpha.0-lark.1.binary', source: 'git@code.byted.org:iOS_Library/toutiao_binary_repo.git'
      if_pod 'LarkCodeCoverage', '5.26.0.5262607'
      if_pod 'CodeCoverageTool', '0.7.0.1-bugfix'
      if_pod 'BDTestCoverage', '1.0.1'
      if_pod 'LarkOfflineCodeCoverage', '5.26.0.5262607'
      if_pod 'LarkSwipeCellKit', '0.22.6'
      if_pod 'Kingfisher', '5.3.1-lark.23'
      if_pod 'KingfisherWebP', '0.6.0-lark.0'
      if_pod 'Swinject', '5.26.0.5265712'
      if_pod 'LarkContainer', '5.31.0.5463996'
      if_pod 'LarkGuide', '5.30.0.5428090'
      if_pod 'LarkGuideUI', '5.30.0.5410491'
      if_pod 'LarkFoundation', '5.31.0.5470696'
      if_pod 'LarkUIKit', '5.31.0.5461589'
      if_pod 'LarkAssetsBrowser', '5.32.0.5484520'
      if_pod 'LarkImageEditor', '5.31.0.5463996', subspecs: %w[V1 CropV2]
      if_pod 'LarkOCR', '5.30.0.5410491'
      if_pod 'LarkRustClient', '5.29.0.5409259', pods: %w[LarkRustClientAssembly]
      if_pod 'LarkRustClientAssembly', '5.31.0.5463996'
      if_pod 'LarkAssembler', '0.0.28'
      if_pod 'Logger', '5.31.0.5463996', subspecs: %w[Core Lark]
      if_pod 'LKContentFix', '5.26.0.5257287'
      if_pod 'LarkFeatureGating', '5.32.0.5485092', subspecs: %w[Core]
      if_pod 'LarkFeatureSwitch', '5.26.0.5257287'
      if_pod 'LarkTraitCollection', '5.26.0.5262607'
      if_pod 'LarkModel', '5.31.0.5424672'
      if_pod 'EENavigator', '5.31.0.5463996'
      if_pod 'LarkTTNetInitializor', '5.29.0.5404215'

      # 可通过 Bits组件依赖方式集成 RustPB, 避免因修改 common_version_RustPB 带来的冲突
      # 详细操作方式及方案见文档: https://bytedance.feishu.cn/wiki/SjcZw72QNiwqSMkX4tpcHcc2nMd
      # 使用 "common_version_" 开头是为了方便脚本替换，具体请看: git@code.byted.org:lark/pipeline_stript.git
      # 改动下面这行的格式会影响QA发版平台通过正则读取RustSDK版本号，除了更新版本之外不要做其他修改
      common_version_RustPB = '7.10.0-g863627ac5654-1703597115.232589190-alpha'
      if ENV['TMP_PB_VERSION'] && !ENV['TMP_PB_VERSION'].empty?
        common_version_RustPB = ENV['TMP_PB_VERSION']
      end
      if_pod 'RustPB', common_version_RustPB
      if_pod 'SwiftProtobuf', '1.20.103'
      if_pod 'LarkSQLCipher', common_version_RustPB
      if $lark_env.is_ka?
          if_pod 'RustSDK', common_version_RustPB, pods:['bytedt-ios']
      else
          if_pod 'RustSDK', common_version_RustPB, pods: ['LarkKAFKMS', 'bytedt-ios']
      end
      if_pod 'RustSimpleLogSDK', common_version_RustPB
      # 将 ServerPB 与 RustPB 分开来写以减少冲突
      if_pod 'ServerPB', '1.0.4488'
      if_pod 'SuiteAppConfig', '5.26.0.5257287', subspecs: %w[Core Assembly]
      if_pod 'SuiteCodable', '5.31.0.5463996'
      if_pod 'LarkTag', '5.30.0.5410491'
      if_pod 'AppContainer', '5.31.0.5466715'
      if_pod 'LarkSafeMode', '5.31.0.5463996'
      if_pod 'BootManager', '5.31.0.5463996', pods: ['BootManagerDependency']
      if_pod 'BootManagerDependency', '5.26.0.5262607'
      if_pod 'BootManagerConfig', '5.29.0.5390437'
      if_pod 'LKLoadable', '5.26.0.5257287'
      if_pod 'LarkSceneManager', '5.30.0.5410491', subspecs: %w[Core Extensions]
      if_pod 'LarkSceneManagerAssembly', '5.26.0.5262607'
      if_pod 'LarkSceneManager', :pods => ['LarkSceneManagerAssembly']
      if_pod 'LarkCamera', '5.30.0.5410491'
      if_pod 'LarkCanvas', '5.30.0.5410491'
      if_pod 'LarkBlur', '5.31.0.5463996'
      if_pod 'LarkEmotion', '5.31.0.5472529', subspecs: %w[Core Assemble]
      if_pod 'EENotification', '5.26.0.5257287'
      if_pod 'NotificationUserInfo', '5.26.0.5257287'
      if_pod 'LarkCompatible', '5.26.0.5257287'
      if_pod 'LarkExtensions', '5.31.0.5455208'
      if_pod 'RoundedHUD', '5.30.0.5410491'
      if_pod 'LarkActionSheet', '5.31.0.5463996'
      if_pod 'EEFlexiable', '0.1.9'
      if_pod 'AsyncComponent', '5.28.0.5358506'
      if_pod 'LKRichView', '5.31.0.5463996'
      if_pod 'TangramComponent', '0.2.32'
      if_pod 'TangramLayoutKit', '0.1.26'
      if_pod 'TangramUIComponent', '5.31.0.5479096'
      if_pod 'TangramService', '5.31.0.5479096'
      if_pod 'RenderRouterInterface', '0.0.1'
      if_pod 'LarkPageController', '5.31.0.5463996'
      if_pod 'EditTextView', '5.31.0.5463996'
      if_pod 'LarkAudioKit', '5.28.0.5366422'
      if_pod 'LarkAudioView', '0.22.26'
      if_pod 'EETroubleKiller', '5.26.0.5257287'
      if_pod 'LarkStorageCore', '0.0.1', subspecs: ['Lark', 'KeyValue', 'Sandbox']
      if_pod 'LarkStorage', '5.31.0.5481213', subspecs: ['Lark', 'KeyValue', 'Sandbox'], :pods => ['LarkStorageAssembly']
      if_pod 'LarkStorageAssembly', '5.31.0.5450972'
      if_pod 'LarkClean', '0.0.1', :pods => ['LarkCleanAssembly']
      if_pod 'LarkCleanAssembly', '0.0.1'
      if_pod 'RxDataSources', '4.0.1', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'Action', '4.0.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'NSObject+Rx', '5.0.0'
      if_pod 'LarkAlertController', '5.30.0.5410491'
      if_pod 'EEPodInfoDebugger', '5.27.0.5296218'
      if_pod 'RunloopTools', '5.26.0.5265712'
      if_pod 'LarkKeyboardKit', '5.26.0.5257287'
      if_pod 'LarkKeyCommandKit', '5.26.0.5257287', subspecs: %w[Core Extensions]
      if_pod 'LarkInteraction', '5.26.0.5262607'
      if_pod 'LarkOrientation', '5.26.0.5257287'
      if_pod 'LarkBGTaskScheduler', '5.26.0.5257287'
      if_pod 'LarkPushTokenUploader', '5.26.0.5262607'
      if_pod 'LarkMonitor', '5.31.0.5483823'
      if_pod 'LarkOpenTrace', '5.26.0.5257287'
      if_pod 'ThreadSafeDataStructure', '5.31.0.5470696'
      if_pod 'LarkTracker', '5.30.0.5441697'
      if_pod 'LarkAppLog', '5.26.0.5257287'
      if_pod 'EEAtomic', '5.26.0.5257287'
      if_pod 'LarkLeanMode', '5.31.0.5463996'
      if_pod 'LarkSnsShare', '5.30.0.5410491', **$lark_env.oversea({ subspecs: ['InternationalSnsShareDependency'] }, { subspecs: ['InternalSnsShareDependency'] })
      if_pod 'LarkShareToken', '5.30.0.5410491'
      if_pod 'LarkPushCard', '5.30.0.5410491'
      if_pod 'LarkActivityIndicatorView', '5.31.0.5463996'
      if_pod 'LarkResource', '5.26.0.5257287'
      if_pod 'LarkUIExtension', '5.26.0.5262607'
      if_pod 'LarkAddressBookSelector', '5.31.0.5463996'
      if_pod 'LarkListItem', '5.31.0.5463996'
      if_pod 'LarkFileKit', '5.31.0.5463996'
      if_pod 'AllLoadCost', '0.4.1'
      if_pod 'AllStaticInitializerCost', '5.26.0.5262607'
      if_pod 'LKWindowManager', '5.30.0.5416280'
      if_pod 'LarkQuickLaunchBar', '0.0.1'
      if_pod 'LarkQuickLaunchInterface', '0.0.1'
      if_pod 'LarkFontAssembly', '0.0.3'

      if_pod 'LarkMagic', '5.27.0.5324666', pods: ['LarkMagicAssembly']
      if_pod 'LarkMagicAssembly', '5.26.0.5262607'
      if_pod 'lottie-ios', '2.6.5'
      if_pod 'lottie-lark', '4.2.7-lark'
      if_pod 'LarkShareContainer', '5.30.0.5410491'
      if !$lark_env.is_oversea
        if_pod 'IESGeckoKit', '3.4.3-alpha.1', subspecs: ['Config/CN', 'Core', 'Downloader']
      else
        if_pod 'IESGeckoKit', '3.1.44-rc.0-lark', subspecs: ['Config/OS', 'Core', 'Downloader']
      end
      if_pod 'LarkGeckoTTNet', '5.31.0.5452567'
      if_pod 'LarkBaseService', '5.31.0.5484102', subspecs: ['Core']

      if_pod 'LarkBytedCert', '5.31.0.5454457'
      if_pod 'LarkDynamicResource', '5.26.0.5262607'
      if_pod 'LarkExtensionServices', '5.31.0.5479662', subspecs: ["Config", "Log", "Account", "Track", "Network", "Domain", "KeyValue"]
      if_pod 'LarkExtensionAssembly', '5.31.0.5463996'
      if_pod 'LarkNotificationServiceExtension', '5.31.0.5483823'
      if_pod 'LarkMinimumMode', '5.30.0.5410491'
      if_pod 'FigmaKit', '5.26.0.5262607'
      if_pod 'LarkFloatPicker', '5.31.0.5463996'
      if_pod 'TTMacroManager', '1.1.0'
      if_pod 'KAFileInterface', '0.0.2'
      if_pod 'LarkKASDKAssemble', ''
      if_pod 'LarkCreateTeam', '5.31.0.5470170'
      if_pod 'FlowChart', '5.26.0.5262607'
      if_pod 'PresentContainerController', '5.31.0.5463996'
      if_pod 'LarkExtensionCommon', '5.31.0.5451694'
      if_pod 'LarkDowngrade','0.0.1'
      if_pod 'LarkPerfBase','0.0.1'
      if_pod 'LarkDowngradeAssembly','0.0.1'
      if_pod 'LarkPreload', '0.0.3'
      if_pod 'LarkPreloadDependency', '0.0.2'
      if_pod 'LarkKeepAlive', '0.0.1'
    end

    def lark_thirdPartyPods
      lark_pod_heimdallr
      if_pod 'Alamofire', '4.7.3', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'DateToolsSwift', '5.0.0'
      if_pod 'FMDB', '2.7.10'
      if_pod 'KeychainAccess', '3.1.2'
      if_pod 'JSONModel', '1.8.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'RxSwift', '5.1.1', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'RxCocoa', '5.1.1', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'SnapKit', '5.0.1-fork.14', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'SSZipArchive', '2.5.1'
      if_pod 'ReachabilitySwift', '4.3.0'
      if_pod 'Yoga', '1.9.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'UIImageViewAlignedSwift', '0.6.0'
      if_pod 'SkeletonView', '1.4.1'
      if_pod 'CryptoSwift', '1.3.3'
      if_pod 'SwiftyJSON', '4.1.0', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'HandyJSON', '5.0.4-beta', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'MBProgressHUD', '1.2.0', source: 'git@code.byted.org:iOS_Library/publicthird_source_repo.git'
      if_pod 'ESPullToRefresh', '3.0.1'
      if_pod 'libPhoneNumber-iOS', '0.9.15'
      if_pod 'LarkSegmentedView', '5.31.0.5463996'
      if_pod 'libpng', '~> 1.6.35'
      if_pod 'LarkCombine', '5.30.0.5428090'
      if_pod 'LarkOpenCombine', '5.31.0.5463996'
      if_pod 'LarkOpenCombineDispatch', '0.0.9'
      if_pod 'LarkOpenCombineFoundation', '0.0.9'
      if_pod 'TTTopSignature', '0.0.22.1.binary'
      if_pod 'gaia_lib_publish', '14.5.0.1-D.1.binary', subspecs: %w[gaia Math Thread]
      if_pod 'BDTuring', '2.2.9-alpha.1-larkbuildfix'
      if_pod 'FLAnimatedImage', '1.0.14', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'MMKVCore', '1.2.7-lark'
      if_pod 'MMKV', '1.2.7-lark'
      if_pod 'MMKVAppExtension', '1.2.7-lark'

      # Pods for google
      if_pod 'AppAuth', '1.4.0'
      if_pod 'GTMAppAuth', '1.1.0'
      if_pod 'GTMSessionFetcher', '1.5.0'

      lark_reactNativePods
    end

    def lark_reactNativePods
      react_pod_version = '0.61.2.6-socket'
      # React-Core
      if_pod 'React-Core', react_pod_version, :subspecs => ['DevSupport', 'Default', 'RCTWebSocket']
      if_pod 'React-jsi', react_pod_version
      if_pod 'React-cxxreact', react_pod_version
      if_pod 'React-jsiexecutor', react_pod_version
      if_pod 'React-jsinspector', react_pod_version
      if_pod 'ReactCommon', react_pod_version, :subspecs => ['turbomodule/core']

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
      if_pod 'LarkDebug', '5.31.0.5463996', subspecs: ['core']
      if_pod 'LarkAssertConfig', '0.0.1'
      if $lark_env.testable || $lark_env.is_binary_cache_job
        if_pod 'LarkDebug', subspecs: ['Flex', 'Assert']
        if_pod 'RangersAppLog', subspecs: %w[ET]
      end
      if $lark_env.anywhereDoorEnable?
          if_pod 'LarkRustClientAssembly', :pods => ['AWEAnywhereArena']
          if_pod 'AWEAnywhereArena', '0.4.0-rc.15'
      end
      if_pod 'LarkDebugExtensionPoint', '3.42.0'
      if_pod 'DebugRouter', '2.1.5'
      if_pod 'TTMLeaksFinder', '2.1.9-alpha.10-swift'
      if_pod 'FBRetainCycleDetector', '0.2.0-alpha.30-swift'
      if_pod 'FLEX', '5.22.10'
      if_pod 'ByteViewDebug', '5.28.0.1'
      # Gecko Debug 头文件存在编译问题，暂时屏蔽
      # pod 'IESGeckoKitDebug', '2.3.1', :subspecs => ['Core']
      if_pod 'SwiftLint', "0.51.0"
      if_pod 'PassportDebug', '5.31.0.5463996'
    end

    # 多媒体相关的 Pod，互相有依赖，升级时可能需要一起
    def lark_pod_media
      # ByteRtcSDK/ByteRtcScreenCapturer 为lto开启组件，为了减少开发链接过程中的lto再编译时间，更新这两个的时候请参考rtcsdk_version函数按照/正式非正式版本同时更新。和RTC方约定lto版本第四段比非lto包多100，其他后缀变更的情况RTC会通知的
      rtcsdk_lto_version, rtcsdk_nolto_version = lto_module_version('3.56.1.510900', :rtcsdk) #非正式版本加参数false，具体请看此函数实现
      if_pod 'ByteRtcSDK',  $lark_env.use_module_nolto(rtcsdk_nolto_version, rtcsdk_lto_version)
      if_pod 'ByteRtcScreenCapturer', $lark_env.use_module_nolto(rtcsdk_nolto_version, rtcsdk_lto_version)

      # 实名 SDK
      if_pod 'byted_cert', '4.10.2-alpha.36', subspecs: %w[core bridgecore offline download crypto]
      if_pod 'AliyunFaceSDK', '2.0.1'
      if_pod 'arkcrypto-minigame-iOS', '0.1.6.5'

      # AI lib 提供的图像处理的库：扫码、人脸识别
      if_pod 'smash',
             '9.0.4-alpha.0-lark-stable',
             subspecs: %w[
               private_utils
               qrcode
               action_liveness
               utils
               package
             ]
      if_pod 'mobilecv2', '1.8.28'
      if_pod 'lens', '8.5.18-lark.1-binary', source: 'git@code.byted.org:iOS_Library/privatethird_binary_repo.git'
      if_pod 'fastcv', '3.3.2.1-binary', source: 'git@code.byted.org:iOS_Library/privatethird_binary_repo.git'
      if_pod 'StarkGameApi', '0.0.4.1-binary'
      if_pod 'StarkNetLib', '0.0.6.1-binary'
      # smash内部依赖espresso
      if_pod 'espresso', '3.0.1'
    end

    def lark_pod_video_editor
      # 视频转码、压缩相关
      # Video transcode
      if_pod 'TTVideoEditor',
             '14.5.0.51-feishu-larkupdate-alpha.48.1.binary',
             subspecs: %w[LarkMode],
             source: 'git@code.byted.org:iOS_Library/privatethird_binary_repo.git'
      if_pod 'audiosdk-mac', '14.4.2' # TTVideoEditor依赖，用不上，但要锁定版本避免resolve速度劣化
      if_pod 'IESAppLogger_iOS',
             '0.1.0.1-binary',
             subspecs: ['OCInterface'],
             source: 'git@code.byted.org:iOS_Library/privatethird_binary_repo.git'


      # Base
      if_pod 'IESInject', '3.11.4-alpha.2'
      if_pod 'IESLiveResourcesButler', '1.9.4'

      # CreationKit*
      if_pod 'CreativeKit', '19.9.5-alpha.10-larktest.1.binary'
      if_pod 'CreationKitArch', '19.9.4-alpha.0-larktest.1.binary', :subspecs => [
        'CameraArch',
        'Models'
      ]
      if_pod 'CreationKitInfra', '19.9.6-alpha.0-lark.1.binary'
      if_pod 'CreationKitBeauty', '20.1.0-alpha.24-larktest.1.binary'
      if_pod 'CreationKitComponents', '19.9.5-alpha.19-larktest.1.binary', :subspecs => [
        'Recorder/BeautyPanelComponent/Core',
        'Recorder/BeautyPanelComponent/Dependencies',
        'Recorder/BeautyPanelComponent/Service',
        'Recorder/Filter/Core',
        'Recorder/Filter/Dependencies',
        'Recorder/Filter/Service'
      ]
      if_pod 'CreationKitRTProtocol', '19.9.0.4-alpha.5-larktest.1.binary'
      if_pod 'CreativeAlbumKit', '19.9.6-alpha.1-larktest.1.binary', :subspecs => [
        'Core',
        'Default',
        'DefaultBundle'
      ]
      if_pod 'CreativeKitSticker', '2.0.11.1.binary'
      if_pod 'CameraClient', '19.2.0.35-alpha.70-larktest.1.binary', :subspecs => ['Lark', 'RuntimeDefaultImpl']
      if_pod 'CameraClientModel', '19.2.0.34-alpha.0-larktest.1.binary'

      if_pod 'AWELazyRegister', '11.2.0.51.1.binary'
      if_pod 'libextobjc', '0.4.1'
      if_pod 'MJRefresh', '3.1.16-douyin'
      if_pod 'ReactiveObjC', '3.1.0'
      if_pod 'AWEBaseModel', '12.6.0.7.1.binary'
      if_pod 'HTSServiceKit', '0.1.3.51.1.binary'
      if_pod 'NLEPlatform', '2.3.1-alpha.0-lark.1.binary'
      if_pod 'NLEEditor', '0.0.0.511-lark.1.binary', :subspecs => ['Adapter','LiteEditor']
      if_pod 'DVETrackKit', '0.0.0.219-lark.1.binary', :subspecs => ['Adapter','DVELiteTrack']
      if_pod 'DVEFoundationKit','0.0.0.77-lark.1.binary'
      if_pod 'DVEInject','0.0.2.1.binary'
      if_pod 'VideoTemplate', '4.0.171.6-bugfix.1.binary', :subspecs => [
        'Core',
        'GamePlay'
      ]
      if_pod 'DavinciResource','0.0.29-alpha.0'
      if_pod 'IESFoundation', '1.0.17.1.binary'
      if_pod 'IESVideoDetector', '0.0.6.1.binary'
      if_pod 'TemplateConsumer', '0.1.21.1-bugfix.1.binary', :subspecs => [
        'Common'
      ]
      if_pod 'Masonry', '1.1.0'
      if_pod 'TTBridgeUnify', '5.2.13', subspecs: [
        'TTBridge',
        'UnifiedWebView',
        'TTBridgeAuthManager/Core',
        $lark_env.oversea('TTBridgeAuthManager/Core', 'TTBridgeAuthManager')
      ]
      if_pod 'ArtistOpenPlatformSDK', '0.0.1-rc.4.1.binary'
      if_pod 'Aspects', '1.4.1.1.binary'
      if_pod 'FileMD5Hash', '2.0.0'
      if_pod 'pop', '1.0.12.1.binary'
      if_pod 'UITextView+Placeholder', '1.3.1'
      if_pod 'TTFileUploadClient', '1.9.61.2.1.binary'
      if_pod 'Mantle', '2.1.2-rc2'
      if_pod 'AWEBaseLib', '12.2.0.4.1.binary'
      if_pod 'RSSwizzle', '0.1.2.1.binary'
      if_pod 'LarkVideoDirector', '5.30.0.5410491', **$lark_env.feature($lark_env.is_ka, {
        subspecs: %w[Lark CKNLE KA]
      }, {
        subspecs: %w[Lark CKNLE]
      })
      if_pod 'ByteDanceKit', '2.2.10', :subspecs => [
        'Foundation',
        'UIKit',
        'Utilities'
      ]
    end

    def lark_pod_heimdallr
      if_pod 'BDALog', '0.9.1-rc.7.1-binary'
      if_pod 'MemoryGraphCapture', '1.4.6-rc.1'
      if_pod 'BDFishhook', '0.2.13-rc.1'
      if_pod 'AWECloudCommand', '1.3.9'
      if_pod 'FrameRecover', '1.28.0.1.binary',subspecs: [
        'Recover',
        'Log'
      ]
      if_pod 'Hermas', '0.0.5-rc.7'
      if_pod 'BDMemoryMatrix', '0.0.21-rc.1',subspecs: [
        'HMDTracker',
        'Memory'
      ]
      if_pod 'ZstdDecompressKit', '1.0.3', subspecs: [
        'libcommon',
        'Compress',
        'Decompress'
      ]

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
        'MemoryGraph',
        'UIFrozen',
        'WatchdogProtect',
        'ALog',
        'HMDCoreDump',
        'CPUException',
        'ProtectCustomCatch',
        'HMDMetricKit',
        'TTNet',
        'NetworkTraffic',
        'HMDFDMonitor',
        'Dart',
        'HMDCrashPrevent',
        'HMDThreadMonitor',
        'HMDLaunchOptimizer',
        'ClassCoverage',
        'Core',
        'GPUUsage',
        $lark_env.oversea('HMDOverseas', 'HMDDomestic')
      ]
      # bytest专属，线下APM
      if !$lark_env.bytest_package
        $Heimdallr_subspecs.append('GWPASan')
        $Heimdallr_subspecs.append('HMDMallocHook')
        $Heimdallr_subspecs.append('HMDSlardarMalloc')
      end
       #慢函数
      if $lark_env.evil_method_enable
        $Heimdallr_subspecs.append('HMDEvilMethodTracer')
      end
      if !$lark_env.is_oversea
        $Heimdallr_subspecs.append('CloudCommand')
      end
      if $lark_env.testable
        $Heimdallr_subspecs.append('Zombie')
      end
      if_pod 'Heimdallr', '0.8.45.0-rc.2-Lark',
          source: 'git@code.byted.org:iOS_Library/privatethird_source_repo.git',
          subspecs: $Heimdallr_subspecs
      if !$lark_env.bytest_package
        if_pod 'Heimdallr/GWPASan', :pods => ['HMDGWPASan']
        if_pod 'HMDGWPASan', '0.1.0-alpha.14-TTVideo.1.binary'
      end
    end

    def lark_pod_cjpay
      return if $lark_env.is_oversea # 海外版本不需要引入 cjpay
      if_pod 'CJPay', '6.8.8-rc.48', subspecs: [
#        'PayBiz',
        'UserCenter',
        'BDPay',
        'NativeBindCard',
        'VerifyModules/VerifyModulesBase',
        'VerifyModules/Biopayment',
        'Extensions',
        'Resource',
        'PayWebView',
        'PayCore/Base',
        'MyBankCard',
        'Localized'
      ]
      if_pod 'CJPayDebugTools', '6.8.4-rc.0', subspecs: [
        'BaseEnvConfig',
        'PayManageEnvConfig',
        'Isec'
      ]
      if_pod 'DouyinOpenPlatformSDK', '5.13.0.3-bugfix.1-binary', subspecs: [
        'Core',
        'Auth'
      ]
      if_pod 'TTTAttributedLabel', '2.0.0'
      if_pod 'BDTicketGuard', '2.0.2.1-binary'
#      if_pod 'tfccsdk', '2.1.0', subspecs: ['tfccsm']
    end

    def lark_pod_bullet
      bullet_version = '1.4.7-alpha.31.1-binary'
      if_pod 'BDXServiceCenter', '1.4.7-alpha.31.1-bugfix.1.binary'
      if_pod 'BDXLynxKit', bullet_version
      if_pod 'BDXMonitor', bullet_version
      if_pod 'BDXResourceLoader', bullet_version
      if_pod 'BulletX', bullet_version
      if_pod 'BDXOptimize', bullet_version
      if_pod 'BDXContainer', bullet_version
      if_pod 'BDXRouter', bullet_version
      if_pod 'BDXSchema', bullet_version

      if_pod 'TTNetworkDownloader', '1.1.39'
      # 基于feature/lark分支的版本，如果后续要升级IESWebViewMonitor到最新版本，需要将feature/lark合回master
      if_pod 'IESWebViewMonitor', '1.3.21-rc.18-lark', subspecs: %w[Core CustomInterface Lynx HybridMonitor SettingModel]
      if_pod 'BDJSBridgeAuthManager', '1.4.2', :subspecs => ['Rename']
      if_pod 'BDXBridgeKit', '2.6.3-rc.10.1-bugfix', :subspecs => ['Methods/Info', 'Methods/Route', 'Methods/Storage', 'Methods/Log', 'Methods/Event', 'Methods/UI', 'Methods/Media', 'Methods/Network']
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

      if_pod 'TTVideoEngine', '1.10.108.111-lark', **$lark_env.oversea({ subspecs: %w[SG TraceReport] }, { subspecs: %w[CN TraceReport] }) # （点播SDK）
      if_pod 'ABRInterface', '2.2.7' # （ABR接口组件）
      if_pod 'ABRModule', '2.2.7'
      if_pod 'VCBaseKit', '1.1.0'
      if_pod 'TTNetworkPredict', '0.5.2', subspecs: ['algorithms', 'bridge', 'common', 'public']
      if_pod 'VCPreloadStrategy', '1.108.2-lark.1.binary', subspecs: ['PlayRange'] # （预加载组件）
      if_pod 'VCVodSettings', '1.0.0.1-binary'

      if_pod 'TTPlayerSDK', '2.10.108.212-lark' # （播放SDK）
      if_pod 'audiosdk', '14.30.2-common.1.binary'
      if_pod 'TTFFmpeg', '1.25.108.22-net3' # （支持mp3、mjepg）
      if_pod 'BVCParser', '0.7.0'
      if_pod 'lib_h_dec', '1.6.207' # 自研 265 解码器
      if_pod 'boringssl', '0.2.3-lark'
      if_pod 'MDLMediaDataLoader', '1.1.108.101' # （数据模块）
      if_pod 'VCNVCloudNetwork', '5.1.1-net3' # （内部网络库，数据模块+上传需要一起升级）

      if_pod 'TTReachability', '1.8.6'
      if_pod 'TTNetworkManager', '4.1.137.13-lark'

      if_pod 'protobuf_lite', '1.0.4-ttnet3'
      if_pod 'SAMKeychain', '1.5.2.1-binary'

      if_pod 'RangersAppLog', '6.15.5.1-bugfix', $lark_env.is_ka ? { subspecs: %w[Core Filter Encryptor/SM2] } : { subspecs: %w[Core Filter] }

      if_pod 'BDTrackerProtocol', '2.6.12'
      if_pod 'OneKit', '1.1.30', subspecs: %w[BaseKit Reachability StartUp Service]
      if_pod 'BDWebImage', '1.8.30.1',
             subspecs: %w[Core Download Decoder]
      if_pod 'libwebp', '1.3.2', source: 'git@code.byted.org:ee/pods_specs.git'
      if_pod 'libttheif_ios', '1.1.13.1-binary',
             source: 'git@code.byted.org:iOS_Library/privatethird_binary_repo.git'
      if_pod 'YYCache', '4.11.3-lark.2'
      unless $lark_env.is_oversea # 非国外版
        if_pod 'BDUGShare', '2.1.4-rc.12', subspecs: [
          'BDUGShareBasic/BDUGUtil',
          'BDUGShareBasic/BDUGWeChatShare',
          'BDUGShareBasic/BDUGWeiboShare',
          'BDUGShareBasic/BDUGQQShare'
        ]
        if_pod 'WechatSDK', '0.3.3', source: 'git@code.byted.org:iOS_Library/privatethird_source_repo.git'
        if_pod 'WeiboSDK', '3.3.5'
        if_pod 'TencentQQSDK', '1.1.0-rc.0.1.binary'
        if_pod 'BDUGSecure', '0.3.0.1-bugfix'
      end
      if_pod 'BDABTestSDK', '1.0.4-rc.9'
      if_pod 'IESJSBridgeCore', '2.1.0'
      if_pod 'BDWebKit', '2.0.5-douyin', subspecs: %w[SecureLink Core Falcon Offline]
      if_pod 'BDPreloadSDK', '0.4.10'
      if_pod 'Gaia', '3.1.5'
      if_pod 'BDAssert', '2.0.0'
      if_pod 'BDMonitorProtocol', '1.1.1'
      if_pod 'BDWebCore', '2.1.2'
      if_pod 'LarkSettingUI', '5.27.0.5295515'
      if_pod 'LarkOpenSetting', '5.31.0.5482869'
      if_pod 'ADFeelGood', '2.1.18-alpha.4-lark'
      if_pod 'CookieManager', '5.31.0.5467269'
      if_pod 'LarkOpenChat', '5.31.0.5479096'
      if_pod 'LarkOpenIM', '5.30.0.5422546'
      if_pod 'BDUGAccountOnekeyLogin', '2.1.5'
      if_pod 'BDUGUnionSDK', '3.0.2'  # 指明联通SDK版本
      if_pod 'bytedt-ios', '2.0.3-lark', subspecs: ['Core']
      if_pod 'protobuf_pty', '0.0.3.1-binary'
      if_pod 'AMapFoundation-NO-IDFA', '1.6.9'
      if_pod 'AMapLocation-NO-IDFA', '2.8.0'
      if_pod 'BDAlogProtocol', '1.3.3.0-rc.0'
      if_pod 'BDModel', '0.1.2'
      if_pod 'BDNetworkTag', '0.3.1'
      if_pod 'BDUGContainer', '1.1.2'
      if_pod 'BDUGMonitorInterface', '1.2.2'
      if_pod 'BDUGTrackerInterface', '1.2.0'
      if_pod 'BitableBridge', '2.0.1'
      if_pod 'boost-for-react-native', '1.63.0'
      if_pod 'CocoaAsyncSocket', '7.6.5'
      if_pod 'Differentiator', '4.0.1'
      if_pod 'DoubleConversion', '1.1.6'
      if_pod 'EAccountApiSDK', '1.4.0-alpha.0'
      if_pod 'Folly', '2018.10.22.00', subspecs: %w[Default]
      if_pod 'glog', '0.3.5'
      if_pod 'Godzippa', '2.1.1'
      if_pod 'HeimdallrForExtension', '0.0.2-alpha.9', subspecs: %w[HMDDyldExtension]
      if_pod 'IESGeckoEncrypt', '0.0.2.1-binary', subspecs: %w[Core]
      if_pod 'IESMetadataStorage', '1.0.20'
      if_pod 'IESPrefetch', '1.1.11'
      if_pod 'Jato', '0.0.5-rc.2', subspecs: %w[PageIn]
      if_pod 'KVOController', '1.2.0'
      if_pod 'libyuv-iOS', '1.0.2'
      if_pod 'LookinServer', '1.2.4', subspecs: %w[Core]
      if_pod 'MJExtension', '3.1.15.7'
      if_pod 'nanosvg', '0.1.10'
      if_pod 'Napi', '2.0.7.5-bugfix.1.binary', subspecs: %w[Core]
      if_pod 'Objection', '1.6.1'
      if_pod 'PocketSVG', '2.7.0'
      if_pod 'ReSwift', '6.0.0'
      if_pod 'RxRelay', '5.1.1'
      if_pod 'SDWebImage', '5.11.1', subspecs: %w[Core]
      if_pod 'SGPagingView', '1.7.2'
      if_pod 'Stinger', '1.0.5', subspecs: %w[Core libffi]
      if_pod 'TTRoute', '0.2.33'
      if_pod 'TTSVGView', '0.1.12'
      if_pod 'TYRZApiSDK', '9.6.3'
      if_pod 'yaml-cpp', '0.6.2.4'
    end
  end
end
# rubocop:enable Layout/LineLength, Metrics/MethodLength
