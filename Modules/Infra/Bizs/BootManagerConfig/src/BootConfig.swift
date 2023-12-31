//
//  BootConfig.swift
//  BootManager
//
//  Created by sniperj on 2021/4/19.
//

import Foundation

/// Flow类型
public enum FlowType: String {
    // didFinishLaunch启动流程
    case didFinishLaunchFlow
    // 登陆之前的流程
    case beforeLoginFlow
    // 登陆之后的流程
    case afterLoginFlow
    // 切换租户的流程
    case afterSwitchFlow
    // 登陆成功的流程
    case loginSuccessFlow
    // 创建团队的流程
    case createTeamFlow
    // 登陆流程
    case loginFlow
    // 登出流程
    case logoutFlow
    // 隐私协议弹窗流程
    case privacyAlertFlow
    // 启动引导流程
    case launchGuideFlow
    // 视频会议游客模式流程
    case vcGuestMeetingFlow
    case launchGuideLoginFlow
    // 安全模式
    case safeModeFlow
    // Passport 迁移流程
    case passportMigrationFlow
    // passport 统一did升级流程
    case passportDIDUpgradeFlow
    // 本地数据加密密钥升级流程
    case encryptionUpgradeFlow
    // 数据擦除流程
    case dataEraseFlow
    // 首屏渲染后
    case afterFirstRender
    // Trigger by runloopIdle
    case runloopIdle
    // Trigger by cpu free
    case cpuIdle
}

// 每个flowType对应的LaunchFlow需要在flowMap中添加
public let flowMap: [FlowType: FlowConfig] = [.didFinishLaunchFlow: didFinishLaunchFlow,
                                    .runloopIdle: runloopIdle,
                                    .cpuIdle: cpuIdle,
                                    .afterLoginFlow: afterLoginFlow,
                                    .afterFirstRender: afterFirstRender,
                                    .safeModeFlow: safeModeFlow,
                                    .dataEraseFlow: dataEraseFlow,
                                    .beforeLoginFlow: beforeLoginFlow,
                                    .afterSwitchFlow: afterSwitchFlow,
                                    .loginSuccessFlow: loginSuccessFlow,
                                    .createTeamFlow: createTeamFlow,
                                    .privacyAlertFlow: privacyAlertFlow,
                                    .launchGuideFlow: launchGuideFlow,
                                    .loginFlow: loginFlow,
                                    .vcGuestMeetingFlow: vcGuestMeetingFlow,
                                    .launchGuideLoginFlow: launchGuideLoginFlow,
                                    .passportMigrationFlow: passportMigrationFlow,
                                    .passportDIDUpgradeFlow: passportDIDUpgradeFlow,
                                    .encryptionUpgradeFlow: encryptionUpgradeFlow,
                                    .logoutFlow: logoutFlow]

// 完整的启动流程didFinishLaunch流程结束之后
// 如果登录成功监听runloop事件，和CPU状态，触发runloopIdle Flow && CPU_Free Flow
// 执行runloopIdle CPU空闲的时候触发CPU Free
// -----------didFinishLaunch---------------------|                    |---runloopIdle--|--CPU Free--|
//                                               |------------------> |                     |            |
//                                               |                    |                     |            |
//                                               |                    |                     |            |
// main -> beforeLoginFlow -> afterLoginFlow ____|                    |                     |            |
//          |                                    |                    |                     |            |
//          |                                    |                    |                     |            |
//          |                                    |                    |                     |            |
//          |                                    |                    |                     |            |
//          |----->privacyAlertFlow------------>LoginFlow             |                     |            |
//                                               |                    |                     |            |
//                                               |->LoginSucessFlow   |                     |            |
//                                                  |                 |                     |            |
//                                                  |->afterLoginFlow |                     |            |
//                                                      |             |                     |            |
//                                                      |-----------> |                     |            |
// --------------------------------------------------------------------------------------------------------

// MARK: - didFinishLaunchFlow
let didFinishLaunchFlow =
    FlowConfig(.didFinishLaunchFlow)
        .flows {
            beforeLoginFlow
            afterLoginFlow
    }
// MARK: - privateAlertFlow
let privacyAlertFlow =
    FlowConfig(.privacyAlertFlow)
        .tasks {
            TaskConfig("SetupDebugTask")
            TaskConfig("PrivacyBizTask")
    }
// MARK: - safeModeFlow
let safeModeFlow =
    FlowConfig(.safeModeFlow)
        .tasks {
            TaskConfig("SetupLoggerTask")
            TaskConfig("StartApplicationTask")
            TaskConfig("SetupMonitorTask")
            TaskConfig("LarkEnterSafeModeTask")
    }
// MARK: - dataEraseFlow
let dataEraseFlow =
    FlowConfig(.dataEraseFlow)
        .tasks {
            TaskConfig("SetupTTNetTask")
            TaskConfig("PassportBootupUserDataEraseTask")
    }
// MARK: - createTeamFlow
let createTeamFlow =
    FlowConfig(.createTeamFlow)
        .tasks {
            TaskConfig("CreateTeamTask")
        }.flows {
            loginSuccessFlow
            afterLoginFlow
    }
// MARK: - afterSwitchFlow
let afterSwitchFlow =
    FlowConfig(.afterSwitchFlow)
        .tasks {
            TaskConfig("WidgetLaunchTask")
        }.flows {
            loginSuccessFlow
            afterLoginFlow
    }
// MARK: - vcGuestMeetingFlow
let vcGuestMeetingFlow =
    FlowConfig(.vcGuestMeetingFlow)
        .tasks {
            TaskConfig("SettingLaunchTask")
            TaskConfig("EmotionResouceTask")
            TaskConfig("EmojiPanelResouceTask")
            TaskConfig("OrientationTask")
            TaskConfig("SetupDocsTask")
            TaskConfig("SetupCookieTask")
            TaskConfig("SetupDocsHandleLoginTask")
            TaskConfig("ByteView.SetupLoggerTask")
            TaskConfig("SetupRustTask")
            TaskConfig("ByteView.GuestSetupTask")
            TaskConfig("ByteView.GuestJoinMeetingTask")
        }
// MARK: - loginSuccessFlow
let loginSuccessFlow =
    FlowConfig(.loginSuccessFlow)
        .tasks {
            TaskConfig("SetupGuideTask")
            TaskConfig("OfflineResourceTask")
            TaskConfig("ByteView.GuestBranchTask")
                .canCheckout {
                    vcGuestMeetingFlow
                }
            TaskConfig("SetupCookieTask")
            TaskConfig("IndustryOnboardingTask")
            TaskConfig("BlockLaunchTask")
    }
// MARK: - loginFlow
let loginFlow =
    FlowConfig(.loginFlow)
        .tasks {
            TaskConfig("LoginTask")
        }.flows {
            //新增flow 需要在logoutFlow同时追加
            //有疑问可以咨询：caiweiwei.liam@bytedance.com
            loginSuccessFlow
            afterLoginFlow
    }

// MARK: - logoutFlow
let logoutFlow =
    FlowConfig(.logoutFlow)
        .tasks {
            TaskConfig("PassportLogoutUserDataEraseTask")
        }.flows {
            loginFlow
            loginSuccessFlow
            afterLoginFlow
    }

// MARK: - launchGuideLoginFlow
let launchGuideLoginFlow =
    FlowConfig(.launchGuideLoginFlow)
        .flows {
            loginSuccessFlow
            afterLoginFlow
    }
// MARK: - launchGuideFlow
let launchGuideFlow =
    FlowConfig(.launchGuideFlow)
        .tasks {
            TaskConfig("SetupDebugTask")
            TaskConfig("SuiteLoginFetchConfig")
            // TaskName: LarkBoxSettingTask
            // Des: 审核开关配置获取
            // Owner: 胡金藏
            // Email: aslan.hu@bytedance.com
            // Module: Infra
            TaskConfig("LarkBoxSettingTask")
            TaskConfig("LKContentFixTask")
            TaskConfig("LaunchGuideTask")
                .canCheckout {
                    loginFlow
                    createTeamFlow
                    launchGuideLoginFlow
                }
    }
// MARK: - passportMigrationFlow
let passportMigrationFlow =
    FlowConfig(.passportMigrationFlow)
        .tasks {
            // TaskName: PassportMigrationTask
            // Des: 将数据迁移到新账号模型
            // Owner: 王昕
            // Email: wangxin.pro@bytedance.com
            // Module: Passport
            TaskConfig("PassportMigrationTask")
                .canCheckout {
                    launchGuideFlow
                    afterLoginFlow
                }
        }
// MARK: - passportMigrationFlow
let passportDIDUpgradeFlow =
    FlowConfig(.passportDIDUpgradeFlow)
        .tasks {
            // TaskName: passportDIDUpgradeTask
            // Des:   统一did升级task
            // Owner: 蔡伟伟
            // Email: caiweiwei.liam@bytedance.com
            // Module: Passport
            //初始化TTNet
            TaskConfig("SetupTTNetTask")
            //初始化RustSDK
            TaskConfig("PreloadLaunchTask")
            //初始化Bootloader
            TaskConfig("StartApplicationTask")
            //初始化rust url protocol
            TaskConfig("SetupURLProtocolTask")
            //开始升级任务
            TaskConfig("PassportDIDUpgradeTask")
        }

let encryptionUpgradeFlow =
    FlowConfig(.encryptionUpgradeFlow)
        .tasks {
            // TaskName: encryptionUpgradeTask
            // Des:   本地数据加密密钥升级流程
            // Owner: 孙行健
            // Email: sunxingjian@bytedance.com
            // Module: SecurityCompliance
            //初始化TTNet
            TaskConfig("SetupTTNetTask")
            //初始化RustSDK
            TaskConfig("PreloadLaunchTask")
            //初始化BootLoader
            TaskConfig("StartApplicationTask")
            //初始化Gecko
            TaskConfig("OfflineResourceTask")
            //初始化统一存储
            TaskConfig("SetupStorageTask")
            //初始化监控
            TaskConfig("SetupMonitorTask")
            //密钥升级任务
            TaskConfig("EncryptionUpgradeTask")
        }

// MARK: - beforeLoginFlow
let beforeLoginFlow =
    FlowConfig(.beforeLoginFlow)
        .tasks {
            // TaskName: LanguageManagerInitTask
            // Des: 多语言SDK的初始化
            // Owner: 王孝华
            // Email: wangxiaohua@bytedance.com
            // Module: Messenger
            TaskConfig("LanguageManagerInitTask")
            // TaskName: LarkMainAssembly
            // Des: 依赖注入容器初始化
            // Owner: 苏鹏
            // Email: supeng.charlie@bytedance.com
            // Module: Messenger
            TaskConfig("LarkMainAssembly")
            // TaskName: LarkSafeModeForemostTask
            // Des: 安全模式
            // Owner: 卢昱泽
            // Email: luyuze.jack@bytedance.com
            // Module: Messenger
            TaskConfig("LarkSafeModeForemostTask")
                .canCheckout {
                    safeModeFlow
                }
            // TaskName: PrivacyMonitorTask
            // Des: 敏感 API Monitor SDK 初始化
            // Owner: huanzhengjie
            // Email: huanzhengjie@bytedance.com
            // Module: SecurityAndCompliance
            TaskConfig("PrivacyMonitorTask")
            // TaskName: SimulatorAndJailBreakCheckTask
            // Des: 模拟器/越狱检测任务
            // Owner: 吴昊天
            // Email: wuhaotian.889@bytedance.com
            // Module: SecurityAndCompliance
            TaskConfig("SimulatorAndJailBreakCheckTask")
            // TaskName: SensitivityControlTask
            // Des: 敏感 API 管控初始化
            // Owner: 王浩
            // Email: wanghao.ios@bytedance.com
            // Module: SecurityAndCompliance
            TaskConfig("SensitivityControlTask")
            // TaskName: PassportBootupUserDataEraseForemostTask
            // Des: 数据擦除任务，只有在登出时数据擦除失败的情况下，才会在app启动时进行数据擦除补偿
            // Owner: caiweiwei
            // Email: caiweiwei.liam@bytedance.com
            // Module: Passport
            TaskConfig("PassportBootupUserDataEraseForemostTask")
                .canCheckout {
                    dataEraseFlow
                }
            // TaskName: FeedBizRegistTask
            // Des: feed页面业务注册
            // Owner: 胡金藏
            // Email: aslan.hu@bytedance.com
            // Module: Messenger
            TaskConfig("FeedBizRegistTask")
            // TaskName: KAVPNInitTask
            // Des: KA VPN EMM 初始化逻辑
            // Owner: 谷浩维
            // Email: guhaowei@bytedance.com
            // Module: KA
            TaskConfig("KAVPNInitTask")
            // TaskName: ThemeLaunchTask
            // Des: 主题fg临时task，用于确保在fg内的用户初始设置为跟随系统
            // Owner: 姚启灏
            // Email: yaoqihao@bytedance.com
            // Module: Messenger
            TaskConfig("ThemeLaunchTask")
            // TaskName: MinimumAssembly
            // Des: 精简模式，安全合规需求
            // Owner: 赵晨
            // Email: zhaochen.09@bytedance.com
            // Module: Messenger
            TaskConfig("MinimumAssembly")
            // TaskName: AccountAssemblyTask
            // Des: Account相关assembly提前初始化
            // Owner: 杨京
            // Email: yangjing.sniper@bytedance.com
            // Module: Messenger
            TaskConfig("AccountAssemblyTask")
            // TaskName: PrivacyCheckTask
            // Des: 隐私协议
            // Owner: 李晨
            // Email: lichen.arthur@bytedance.com
            // Module: Messenger
            TaskConfig("PrivacyCheckTask")
                .canCheckout {
                    privacyAlertFlow
                }
            // TaskName: EncryptionUpgradePrecheckTask
            // Des: 检查是否进行加密密钥升级
            // Owner: 孙行健
            // Email: sunxingjian@bytedance.com
            // Module: SecurityAndCompliance
            TaskConfig("EncryptionUpgradePrecheckTask")
                .canCheckout {
                    encryptionUpgradeFlow
                }
            // TaskName: passportCheckDIDUpgradeTask
            // Des: 检查是否进行统一did升级
            // Owner: 蔡伟伟
            // Email: caiweiwei.liam@bytedance.com
            // Module: Passport
            TaskConfig("PassportCheckDIDUpgradeTask")
                .canCheckout {
                    passportDIDUpgradeFlow
                }
            // TaskName: SetupAlogTask
            // Des: 初始化Alog
            // Owner: 蔡亮
            // Email: cailiang.cl7r@bytedance.com
            // Module: Messenger
            TaskConfig("SetupAlogTask")
            // TaskName: SetupSlardarTask
            // Des: 初始化slardar
            // Owner: 李晨
            // Email: lichen.arthur@bytedance.com
            // Module: Messenger
            TaskConfig("SetupSlardarTask")
            // TaskName: SetupTTNetTask
            // Des: 初始化TTNet
            // Owner: 齐鸿烨sao
            // Email: qihongye@bytedance.com
            // Module: Messenger
            TaskConfig("SetupTTNetTask")
            // TaskName: LarkSafeModeTask
            // Des: 安全模式
            // Owner: 霍云杰
            // Email: huoyunjie@bytedance.com
            // Module: Messenger
            TaskConfig("LarkSafeModeTask")
                .canCheckout {
                    safeModeFlow
                }
            // TaskName: StartTrafficOfLauncherTask
            // Des: 开始收集启动流量
            // Owner: 宋龙彪
            // Email: songlongbiao@bytedance.com
            // Module: Messenger
            TaskConfig("StartTrafficOfLauncherTask")
            // TaskName: LarkQuaterbackTask
            // Des: 热修复SDK的初始化，依赖 AccountAssemblyTask 初始化完成获取 device id
            // Owner: 史江浩
            // Email: shijianghao@bytedance.com
            // Module: Messenger
            TaskConfig("LarkQuaterbackTask")
            // TaskName: CommonSettingLaunchTask
            // Des: 无用户态配置和域名拉取启动任务
            // Owner: 冯科榜
            // Email: fengkebang@bytedance.com
            // Module: LarkSetting
            TaskConfig("CommonSettingLaunchTask")
            // TaskName: PreloadLaunchTask
            // Des: 子线程初始化登录依赖的Service
            // Owner: 朱德亮
            // Email: zhudeliang@bytedance.com
            // Module: Passport
            TaskConfig("PreloadLaunchTask")
            // TaskName: PassportPreloadLaunchTask
            // Des: 子线程初始化登录依赖的Service
            // Owner: 蔡伟伟
            // Email: caiweiwei.liam@bytedance.com
            // Module: Passport
            TaskConfig("PassportPreloadLaunchTask")
            // TaskName: SetupLoggerTask
            // Des: 初始化LarkLogger
            // Owner: 李晨
            // Email: lichen.arthur@bytedance.com
            // Module: Messenger
            TaskConfig("SetupLoggerTask")
            // TaskName: SetupFileTask
            // Des: 初始化LarkLogger
            // Owner: 李晨
            // Email: lichen.arthur@bytedance.com
            // Module: Messenger
            TaskConfig("SetupFileTask")
            // TaskName: SetupStorageTask
            // Des: 初始化 LarkStorage
            // Owner: 张威
            // Email: zhangwei.wy@bytedance.com
            // Module: Messenger
            TaskConfig("SetupStorageTask")
            // TaskName: StartApplicationTask
            // Des: 兼容old launch
            // Owner: 杨京
            // Email: yangjing.sniper@bytedance.com
            // Module: Messenger
            TaskConfig("StartApplicationTask")
            // TaskName: SetupBGTask
            // Des: 后台任务相关初始化
            // Owner: 苏鹏
            // Email: supeng.charlie@bytedance.com
            // Module: Messenger
            TaskConfig("SetupBGTask")
            // TaskName: SetupMonitorTask
            // Des: 监控相关初始化，crash日志
            // Owner: 李晨
            // Email: lichen.arthur@bytedance.com
            // Module: Messenger
            TaskConfig("SetupMonitorTask")
            // TaskName: SetupAppLogTask
            // Des: Account logger初始化
            // Owner: 朱德亮
            // Email: zhudeliang@bytedance.com
            // Module: Passport
            TaskConfig("SetupAppLogTask")
            // TaskName: SuiteLoginLoggerTask
            // Des: SuiteLogin logger初始化
            // Owner: 朱德亮
            // Email: zhudeliang@bytedance.com
            // Module: Passport
            TaskConfig("SuiteLoginLoggerTask")
            // TaskName: ResourceSetupTask
            // Des: 初始化LarkLogger
            // Owner: 李晨
            // Email: lichen.arthur@bytedance.com
            // Module: Messenger
            TaskConfig("ResourceSetupTask")
            // TaskName: ThemeSetupTask
            // Des: 初始化LarkLogger
            // Owner: 李晨
            // Email: lichen.arthur@bytedance.com
            // Module: Messenger
            TaskConfig("ThemeSetupTask")
            TaskConfig("SetupLauncherTask")
            // TaskName: SetupLarkBadgeTask
            // Des: LarkBadge初始化
            // Owner: 姚启灏
            // Email: yaoqihao@bytedance.com
            // Module: Messenger
            TaskConfig("SetupLarkBadgeTask")
            // TaskName: SetupURLProtocolTask
            // Des: URLProtocol注册
            // Owner: 王孝华
            // Email: wangxiaohua@bytedance.com
            // Module: Messenger
            TaskConfig("SetupURLProtocolTask")
            // TaskName: SettingBundleTask
            // Des: 由于离职，不知道这个任务在干嘛
            // Owner: 金建
            // Email: jinjian.au@bytedance.com
            // Module: Passport
            TaskConfig("SettingBundleTask")
            // TaskName: TroubleKillerTask
            // Des: TK平台相关
            // Owner: 李晓蕊
            // Email: lixiaorui@bytedance.com
            // Module: 小程序
            TaskConfig("TroubleKillerTask")
            // TaskName: LarkBoxSettingTask
            // Des: 审核开关配置获取
            // Owner: 胡金藏
            // Email: aslan.hu@bytedance.com
            // Module: Infra
            TaskConfig("LarkBoxSettingTask")
            // TaskName: TourSetupTask
            // Des: 主要是为了尽早的根据did拉取投放来源
            // Owner: 胡金藏
            // Email: aslan.hu@bytedance.com
            // Module: Messenger
            TaskConfig("TourSetupTask")
            // TaskName: SetupOPInterfaceTask
            // Des: 初始化小程序logger
            // Owner: 畅嵘
            // Email: changrong.cory@bytedance.com
            // Module: 小程序
            TaskConfig("SetupOPInterfaceTask")
            // TaskName: SetupCanvasCacheTask
            // Des: 设置LarkCanvas的实现为LarkCache
            // Owner: 黄浩庭
            // Email: huanghaoting@bytedance.com
            // Module: Messenger
            TaskConfig("SetupCanvasCacheTask")
            // TaskName: LogoutPreviousInstallUserTask
            // Des: 清理上一次安装 app 未登出的用户
            // Owner: 金健
            // Email: jinjian.au@bytedance.com
            // Module: Passport
            TaskConfig("LogoutPreviousInstallUserTask")
            // TaskName: WebBeforeLoginTask
            // Des: 飞书Web容器登录前任务，执行初始化HybridMonitir等
            // Owner: 武嘉晟
            // Email: wujiasheng.token@bytedance.com
            // Module: Web
            TaskConfig("WebBeforeLoginTask")
            // TaskName: OpenPlatformBeforeLoginTask
            // Des: 飞书开放平台登录前任务
            // Owner: 陈蒙奇
            // Email: chenmengqi.1024@bytedance.com
            // Module: OpenPlatform
            TaskConfig("OpenPlatformBeforeLoginTask")
            // TaskName: WorkplaceBeforeLoginTask
            // Des: 工作台登陆前任务
            // Owner: 张蒙
            // Email: zhangmeng.94233@bytedance.com
            // Module: Workplace
            TaskConfig("WorkplaceBeforeLoginTask")
            // TaskName: OfflineResourceTask
            // Des: Gecko
            // Owner: 蔡伟伟
            // Email: caiweiwei.liam@bytedance.com
            // Module: Passport
            TaskConfig("OfflineResourceTask")
            // TaskName: FastLoginTask
            // Des: 获取本地用户态快速登录
            // Owner: 金健
            // Email: jinjian.au@bytedance.com
            // Module: Passport
            TaskConfig("FastLoginTask")
                .canCheckout {
                    launchGuideFlow
                    passportMigrationFlow
                }
            // TaskName: AppLockSettingLaunchTask
            // Des: 屏幕锁
            // Owner: 李军
            // Email: lijun.thinker@bytedance.com
            // Module: KA
            TaskConfig("AppLockSettingLaunchTask")
    }
// MARK: - afterLoginFlow
let afterLoginFlow =
    FlowConfig(.afterLoginFlow)
        .tasks {
            // TaskName: ByteView.CallKitSetupTask
            // Des: callkit 初始化任务，须放在 afterLogin 第一个，请勿随意改动!!!
            // Owner: zhangxin.shin
            // Email: zhangxin.shin@bytedance.com
            // Module: ByteView
            TaskConfig("ByteView.CallKitSetupTask")
            // TaskName: FeedPluginBizRegistTask
            // Des: feed页面Cell注册
            // Owner: 胡金藏
            // Email: aslan.hu@bytedance.com
            // Module: Messenger
            TaskConfig("FeedPluginBizRegistTask")
            // TaskName: LoadFeedTask
            // Des: feed页面预加载
            // Owner: 夏汝震
            // Email: xiaruzhen@bytedance.com
            // Module: Messenger
            TaskConfig("LoadFeedTask")
            // TaskName: AnalysisFirstTabTask
            // Des: 获取首个tab的string
            // Owner: 袁平
            // Email: yuanping.0@bytedance.com
            // Module: Messenger
            TaskConfig("AnalysisFirstTabTask")
            // TaskName: EmotionResouceTask
            // Des: 拉取表情资源
            // Owner: 璩介业
            // Email: qujieye@bytedance.com
            // Module: Messenger
            TaskConfig("EmotionResouceTask")
            // TaskName: SetNetworkStatusTask
            // Des: 通知rust当前网络状态
            // Owner: 王元洵
            // Email: wangyuanxun@bytedance.com
            // Module: Messenger
            TaskConfig("SetNetworkStatusTask")
            // TaskName: SettingLaunchTask
            // Des: 加载Setting和FG
            // Owner: 王元洵
            // Email: wangyuanxun@bytedance.com
            // Module: Messenger
            TaskConfig("SettingLaunchTask")
            // TaskName: FontLaunchTask
            // Des: 字体初始化
            // Owner: 董伟
            // Email: dongwei.1615@bytedance.com
            // Module: Messenger
            TaskConfig("FontLaunchTask")
            // TaskName: ABTestSetupTask
            // Des: 注册AB
            // Owner: 王元洵
            // Email: wangyuanxun@bytedance.com
            // Module: Messenger
            TaskConfig("ABTestSetupTask")
            // TaskName: LarkDowngradeTask
            // Des: 降级配置
            // Owner: 宋龙彪
            // Email: songlongbiao@bytedance.com
            // Module: Common
            TaskConfig("LarkDowngradeTask")
            // Des: 初始化preload
            // Owner: 黄立兴
            // Email: huanglx@bytedance.com
            // Module: Messenger
            TaskConfig("PreloadConfigTask")
            // TaskName: MinimumModeTask
            // Des: 精简模式，安全合规需求
            // Owner: 赵晨
            // Email: zhaochen.09@bytedance.com
            // Module: Messenger
            TaskConfig("MinimumModeTask")
            // TaskName: SetupModuleTask
            // Des: 一堆花里胡哨的设置
            // Owner: 杨京
            // Email: yangjing.sniper@bytedance.com
            // Module: Messenger
            TaskConfig("SetupModuleTask")
            // TaskName: PushKitService.SetupTask
            // Des: pushKit初始化，已迁入 ByteView.CallKitSetupTask
            // Owner: 李晨
            // Email: lichen.arthur@bytedance.com
            // Module: Messenger
            // TaskConfig("PushKitService.SetupTask")
            // TaskName: "ByteView.SetupLoggerTask
            // Des: byteViewLogger初始化
            // Owner: 刘建龙
            // Email: liujianlong@bytedance.com
            // Module: 音视频
            TaskConfig("ByteView.SetupLoggerTask")
            // TaskName: UpdateOfflineResource
            // Des: 离线资源更新
            // Owner: 金健
            // Email: jinjian.au@bytedance.com
            // Module: Passport
            TaskConfig("UpdateOfflineResource")
            // TaskName: LarkDynamicResourceTask
            // Des: 动态资源加载
            // Owner: 胡金藏
            // Email: aslan.hu@bytedance.com
            // Module: Messenger
            TaskConfig("LarkDynamicResourceTask")
            // TaskName: ByteView.VCSetupTask
            // Des: byteView业务初始化
            // Owner: 刘建龙
            // Email: liujianlong@bytedance.com
            // Module: 音视频
            TaskConfig("ByteView.VCSetupTask")
            // TaskName: ByteView.VoIPSetupTask
            // Des: byteViewVOIP初始化
            // Owner: 刘建龙
            // Email: liujianlong@bytedance.com
            // Module: 音视频
            TaskConfig("ByteView.VoIPSetupTask")
            // TaskName: SplashLaunchTask
            // Des: 启动闪屏task
            // Owner: 王元洵
            // Email: wangyuanxun@bytedance.com
            // Module: Messenger
            TaskConfig("EMTask")
            // TaskName: EMTask
            // Des: EM 保密需求
            // Owner: 黄浩庭
            // Email: huanghaoting@bytedance.com
            // Module: Messenger
            TaskConfig("SplashLaunchTask")
            // TaskName: PreloadTabServiceTask
            // Des: 预加载navigationInterface
            // Owner: 袁平
            // Email: yuanping.0@bytedance.com
            // Module: Messenger
            TaskConfig("PreloadTabServiceTask")
            // TaskName: ChatterPreloadTask
            // Des: 预加载chatter模块
            // Owner: 苏鹏
            // Email: supeng.charlie@bytedance.com
            // Module: Messenger
            TaskConfig("ChatterPreloadTask")
            // TaskName: UpdateMonitorTask
            // Des: 更新slardar等监控平台的user信息
            // Owner: 杨京
            // Email: yangjing.sniper@bytedance.com
            // Module: Messenger
            TaskConfig("UpdateMonitorTask")
            // TaskName: CalendarSetupTask
            // Des: 日历相关初始化
            // Owner: 朱衡
            // Email: zhuheng.henry@bytedance.com
            // Module: Calendar
            TaskConfig("CalendarSetupTask")
            // TaskName: CalendarPreloadTask
            // Des: 日历相关资源/服务预加载
            // Owner: 赵冬
            // Email: zhaodong.23@bytedance.com
            // Module: Calendar
            TaskConfig("CalendarPreloadTask")
            // TaskName: SetupDocsTask
            // Des: Docs相关初始化
            // Owner: 庄逸众
            // Email: zhuangyizhong@bytedance.com
            // Module: Docs
            TaskConfig("SetupDocsTask")
            // TaskName: RegistWebAppLinkTask
            // Des: 拦截小程序链接使用一方容器打开
            // Owner: majie.7
            // Email: majie.7@bytedance.com
            // Module: CCM
            TaskConfig("RegistWebAppLinkTask")
            // TaskName: SetupCookieTask
            // Des: 同步设置cookie
            // Owner: 齐鸿烨
            // Email: qihongye@bytedance.com
            // Module: Messenger
            TaskConfig("SetupCookieTask")
            // TaskName: SetupDocsHandleLoginTask
            // Des: Docs登录相关
            // Owner: 李晓林
            // Email: lixiaolin.1906@bytedance.com
            // Module: Docs
            TaskConfig("SetupDocsHandleLoginTask")
            // TaskName: LoadDocsTask
            // Des: 加载docs页面
            // Owner: 李泽创
            // Email: lizechuang.lee@bytedance.com
            // Module: Docs
            TaskConfig("LoadDocsTask")
            // TaskName: SetupOpenPlatformTask
            // Des: 小程序初始化
            // Owner: 李论
            // Email: lilun.ios@bytedance.com
            // Module: 小程序
            TaskConfig("SetupOpenPlatformTask")
            // TaskName: SetupLynxTask
            // Des: Lynx相关启动任务
            // Owner: 廉金涛
            // Email: lianjintao@bytedance.com
            // Module: Lynx
            TaskConfig("SetupLynxTask")
            // TaskName: SetupLarkMessageCardTask
            // Des: 消息卡片启动任务
            // Owner: 廉金涛
            // Email: lianjintao@bytedance.com
            // Module: 消息卡片
            TaskConfig("SetupLarkMessageCardTask")
            // TaskName: GadgetSetupTask
            // Des: 小程序登录相关逻辑
            // Owner: 李论
            // Email: lilun.ios@bytedance.com
            // Module: 小程序
            TaskConfig("GadgetSetupTask")
            // TaskName: RunloopAndCpuIdleTask
            // Des: 触发runloop和cpu idle的task
            // Owner: 黄立兴
            // Email: huanglx@bytedance.com
            // Module: Messenger
            TaskConfig("RunloopAndCpuIdleTask")
            // TaskName: SetupDispatcherTask
            // Des: 启动通知Rust
            // Owner: 杨京
            // Email: yangjing.sniper@bytedance.com
            // Module: Messenger
            TaskConfig("SetupDispatcherTask")
            // TaskName: SetupMailTask
            // Des: mail相关初始化
            // Owner: 刘特沨
            // Email: liutefeng@bytedance.com
            // Module: Mail
            TaskConfig("SetupMailTask")
            // TaskName: SetupMaiDelayableTask
            // Des: mail相关初始化，在顶端机场景，允许delay的。
            // Owner: 刘特沨
            // Email: liutefeng@bytedance.com
            // Module: Mail
            TaskConfig("SetupMaiDelayableTask")
            // TaskName: ByteViewTabSetupTask
            // Des: 会议独立Tab初始化
            // Owner: 刘建龙
            // Email: liujianlong@bytedance.com
            // Module: 音视频
            TaskConfig("ByteViewTabSetupTask")
            // TaskName: LarkLiveSetupTask
            // Des: 飞书直播相关初始化
            // Owner: 杨耀
            // Email: yangyao.wildyao@bytedance.com
            // Module: 音视频
            TaskConfig("LarkLiveSetupTask")
            // TaskName: AppReciableSDKInitTask
            // Des: 可感知的初始化
            // Owner: 齐鸿烨
            // Email: qihongye@bytedance.com
            // Module: Messenger
            TaskConfig("AppReciableSDKInitTask")
            // TaskName: NewVersionOnboardingTask
            // Des: 7.0版本新功能引导页
            // Owner: 谢许峰
            // Email: xiexufeng@bytedance.com
            // Module: Messenger
            TaskConfig("NewVersionOnboardingTask")
            // TaskName: SetupMainTabTask
            // Des: 首屏UI初始化
            // Owner: 夏汝震
            // Email: xiaruzhen@bytedance.com
            // Module: Messenger
            TaskConfig("SetupMainTabTask")
            // TaskName: IndustryOnboardingFeedTask
            // Des: 行业onboarding之后打开引导feed
            // Owner: 谢许峰
            // Email: xiexufeng@bytedance.com
            // Module: Messenger
            TaskConfig("IndustryOnboardingFeedTask")
            // TaskName: PrivacyMonitorColdLaunchTask
            // Des: Monitor设置冷启动结束状态
            // Owner: huanzhengjie
            // Email: huanzhengjie@bytedance.com
            // Module: SecurityAndCompliance
            TaskConfig("PrivacyMonitorColdLaunchTask")
            // TaskName: AccountInterrupstHandlerTask
            // Des: 登出中断信号
            // Owner: 金健
            // Email: jinjian.au@bytedance.com
            // Module: Passport
            TaskConfig("AccountInterrupstHandlerTask")
            // TaskName: FinanceLaunchTask
            // Des: 红包支付业务初始化
            // Owner: 方俊
            // Email: fangjun.001@bytedance.com
            // Module: Finance
            TaskConfig("FinanceLaunchTask")
            // TaskName: LarkLynxDevtoolTask
            // Des: LynxDevtool初始化
            // Owner: 陈蒙奇、王飞
            // Email: chenmengqi.1024@bytedance.com , wangfei.heart@bytedance.com
            // Module: Common
            TaskConfig("LarkLynxDevtoolTask")
            // TaskName: HeartBeatTask
            // Des: track device heart beat (get_focus_v2)
            // Owner: hujinzang
            // Email: aslan.hu@bytedance.com
            // Module: Common
            TaskConfig("HeartBeatTask")
    }

let afterFirstRender = 
    FlowConfig(.afterFirstRender)
        .tasks {
            TaskConfig("SetupRustTask")
            // TaskName: LarkSafeModeTask
            // Des: 安全模式
            // Owner: 卢昱泽
            // Email: luyuze.jack@bytedance.com
            // Module: Messenger
            TaskConfig("LarkRuntimeSafeModeTask")
                .canCheckout {
                    safeModeFlow
            }
            // TaskName: AnywhereDoorTask
            // Des: 任意门抓包工具
            // Owner: 王元洵
            // Email: wangyuanxun@bytedance.com
            // Module: Common
            TaskConfig("AnywhereDoorTask")
            // TaskName: SetupPassportTask
            // Des: LKPassportExternal 初始化
            // Owner: 赵翔宇
            // Email: zhaoxiangyu.love@bytedance.com
            // Module: KA
            TaskConfig("SetupPassportTask")
            // TaskName: WorkplaceStartUpTask
            // Des: 工作台登录后初始化（Badge，预加载等）
            // Owner: 张蒙
            // Email: zhangmeng.94233@bytedance.com
            // Module LarkWorkplace
            TaskConfig("WorkplaceStartUpTask")
            // TaskName: SilentModeTask
            // Des: device silent mode
            // Owner: hujinzang
            // Email: aslan.hu@bytedance.com
            // Module: Common
            TaskConfig("SilentModeTask")
            // TaskName: SetupMacTask
            // Des: 禁止mac使用iOS安装包
            // Owner: yaoqihao
            // Email: yaoqihao@bytedance.com
            // Module: Core
            TaskConfig("SetupMacTask")
    }

// MARK: - runloopIdle
let runloopIdle =
    FlowConfig(.runloopIdle)
        .tasks {
            TaskConfig("IdleLoadTask")
            // TaskName: CheckAppLockSettingLaunchTask
            // Des: 检测屏幕锁状态
            // Owner: 刘晚林
            // Email: liuwanlin@bytedance.com
            // Module: KA
            TaskConfig("CheckAppLockSettingLaunchTask")
            // TaskName: MemoryPressureMonitorLaunchTask
            // Des: 内存压力监听
            // Owner: 蔡亮
            // Email: cailiang.cl7r@bytedance.com
            // Module: Messenger
            TaskConfig("MemoryPressureMonitorLaunchTask")
            // TaskName: LarkMeegoBootTask
            // Des: 获取用户是否启用了 meego
            // Owner:施正宇
            // Email: shizhengyu@bytedance.com
            // Module: LarkMeego
            TaskConfig("LarkMeegoBootTask")
            // TaskName: PassportGetUserListTask
            // Des: 获取最新的租户列表
            // Owner: 蔡伟伟
            // Email: caiweiwei.liam@bytedance.com
            // Module: Passport
            TaskConfig("PassportGetUserListTask")
            // TaskName: UnloginProcessHandlerTask
            // Des: 处理缓存需要访问的 URL
            // Owner: 金健
            // Email: jinjian.au@bytedance.com
            // Module: Passport
            TaskConfig("UnloginProcessHandlerTask")
            // TaskName: PassportFirstRenderTask
            // Des: Passport 首屏渲染时的聚合任务集
            // Owner: 金健
            // Email: jinjian.au@bytedance.com
            // Module: Passport
            TaskConfig("PassportFirstRenderTask")
            TaskConfig("LarkMessengerAssembleTask")
            // TaskName: LarkGeckoTTNetTask
            // Des: Gecko 设置 delegate
            // Owner: 赵翔宇
            // Email: zhaoxiangyu.love@bytedance.com
            // Module: Other
            TaskConfig("LarkGeckoTTNetTask")
            // TaskName: ByteView.AccountInterruptTask
            // Des: ByteView登出中断逻辑
            // Owner: 刘建龙
            // Email: liujianlong@bytedance.com
            // Module: 音视频
            TaskConfig("ByteView.AccountInterruptTask")
            // TaskName: PrivacyKitTask
            // Des: 隐私敏感API管控集成，会hook相关的api调用
            // Owner: 王孝华
            // Email: wangxiaohua@bytedance.com
            TaskConfig("PrivacyKitTask")
            TaskConfig("SceneSetupTask")
            TaskConfig("ThemeAnalyticsTask")
            // TaskName: UpdateAuditTask
            // Des: SecurityAuditSDK初始化
            // Owner: 朱德亮
            // Email: zhudeliang@bytedance.com
            TaskConfig("UpdateAuditTask")
            TaskConfig("UpdateWaterMaskTask")
            // TaskName: ExtensionLaunchTask
            // Des: Extension组件集成
            // Owner: 王元洵
            // Email: wangyuanxun@bytedance.com
            // Module: Messenger
            TaskConfig("ExtensionLaunchTask")
            TaskConfig("UpdateTimeZoneTask")
            TaskConfig("ObservePasteboardTask")
            TaskConfig("ContactLaunchTask")
            TaskConfig("SetupKeyboardTask")
            TaskConfig("SuiteLoginAfterAccountLoaded")
            TaskConfig("LKContentFixTask")
            TaskConfig("SetupDebugTask")
            TaskConfig("SetupGuideTask")
            TaskConfig("ForceTouchTask")
            TaskConfig("SetupSafetyTask")
            TaskConfig("ExtensionUpdateTask")
            TaskConfig("OrientationTask")
            TaskConfig("SuiteLoginFetchConfig")
            TaskConfig("LoadSuspendTask")
            TaskConfig("WidgetDataLaunchTask")
            TaskConfig("LarkDynamicResourceSyncTask")
            // TaskName: FlutterContainerTask
            // Des: 注册 flutter 容器相关 Bridge，注入一些基础配置
            // Owner: 施正宇
            // Email: shizhengyu@bytedance.com
            // Module: LarkFlutterContainer
            TaskConfig("FlutterContainerTask")
            // TaskName: RVCSetupTask
            // Des: RVC(Room 虚拟控制器)
            // Owner: 周永南
            // Email: zhouyongnan@bytedance.com
            // Module: 音视频
            TaskConfig("RVCSetupTask")
            // TaskName: UGDialogFetchTask
            // Des: 拉取UG运营弹窗数据，监听tab切换
            // Owner: hujinzang
            // Email: aslan.hu@bytedance.com
            // Module: LarkTour
            TaskConfig("UGDialogFetchTask")
            // TaskName: ForwardSetupTask
            // Des: OpenShare转发
            // Owner: 刘宪宇
            // Email: liuxianyu@bytedance.com
            // Module: Messenger
            TaskConfig("ForwardSetupTask")
            // TaskName: EmojiPanelResouceTask
            // Des: 拉取表情面板资源
            // Owner: 璩介业
            // Email: qujieye@bytedance.com
            // Module: Messenger
            TaskConfig("EmojiPanelResouceTask")
            // TaskName: WhiteBoardSetupTask
            // Des: 白板图片分享
            // Owner: 何利健
            // Email: helijian.666@bytedance.com
            // Module: 音视频
            TaskConfig("WhiteBoardSetupTask")
            // TaskName: LarkSecurityComplianceSyncTask
            // Des: 安全合规
            // Owner: 程庆春
            // Email: chengqingchun@bytedance.com
            // Module: Security&Compliance
            TaskConfig("LarkSecurityComplianceSyncTask")
            //TaskName: LarkEMMSyncTask
            //Des: 安全合规EMM
            //Owner: 王西敬
            //Email: wangxijing@bytedance.com
            //Module: Security&Compliance
            TaskConfig("LarkEMMSyncTask")
            //TaskName: VideoSetupTask
            //Des: setup video engine and video editor
            //Owner: huanghaoting
            //Module: Video
            TaskConfig("VideoSetupTask")
            // TaskName: PowerLogMonitorLaunchTask
            // Des: powerlog monitor
            // Owner: yuanzhangjing
            // Module: Messenger
            TaskConfig("PowerLogMonitorLaunchTask")
            // TaskName: PassportMonitorTask
            // Des: passport monitor task
            // Owner: caiweiwei.liam
            // Module: Passport
            TaskConfig("PassportMonitorTask")
            // TaskName: LarkScreenProtectionLoadServiceTask
            // Des: screen protection load service
            // Owner: yangyifan
            // Module: S&C
            TaskConfig("LarkScreenProtectionLoadServiceTask")
            // TaskName: TenantRestrictTask
            // Des:restrict other tenant login
            // Owner: wangxijing
            //Email: wangxijing@bytedance.com
            // Module: S&C
            TaskConfig("TenantRestrictTask")
            // TaskName: LarkQuaterbackFGTask
            // Des: 热修模块，获取fg
            // Owner: 史江浩
            // Email: shijianghao@bytedance.com
            // Module Common            
            TaskConfig("LarkQuaterbackFGTask")
            // TaskName: SaveRustLogKeyTask
            // Des: 报错setting拉下来的logSecretKey，下次启动传给Rust以及Log模块
            // Owner: 苏鹏
            // Email: supeng.chalrie@bytedance.com
            // Module Common
            TaskConfig("SaveRustLogKeyTask")
    }
// MARK: - CpuIdle
let cpuIdle =
    FlowConfig(.cpuIdle)
        .tasks {
            TaskConfig("LoadUrgentTask")
            TaskConfig("LoadEnterpriseNoticeTask")
            TaskConfig("CalendarLoadTask")
            TaskConfig("VersionCheckTask")
            TaskConfig("I18nLoadFGTask")
            TaskConfig("FetchPayTokenTask")
            TaskConfig("LeanModeLaunchTask")
            TaskConfig("FeedBannerTask")
            TaskConfig("UpdateABTestTask")
            TaskConfig("BGTaskSwitch")
            TaskConfig("SetupICloudTask")
            TaskConfig("SetupCacheTask")
            TaskConfig("LarkMagicLaunchTask")
            TaskConfig("SplashIdleTask")
            TaskConfig("ScreenshotMonitorLaunchTask")
            // TaskName: ScreenCapturedMonitorLaunchTask
            // Des: 移动端增加录屏事件埋点
            // Owner: 赵家琛
            // Email: zhaojiachen.hydra@bytedance.com
            // Module: Messenger
            TaskConfig("ScreenCapturedMonitorLaunchTask")
            // TaskName: SetupIESOuterTestTask
            // Des: 众测sdk 灰度测试能力
            // Owner: 卢昱泽
            // Email: luyuze.jack@bytedance.com
            // Module: Messenger
            //TaskConfig("SetupIESOuterTestTask")
            // TaskName: KAExpiredObserverTask
            // Des: 监听 KA 租户过期配置
            // Owner: 赵翔宇
            // Email: zhaoxiangyu.love@bytedance.com
            // Module: KA
            TaskConfig("KAExpiredObserverTask")
            // TaskName: TempDecodeFileCleanTask
            // Des: 清理端上临时存储的明文文件资源
            // Owner: 赵晨
            // Email: zhaochen.09@bytedance.com
            // Module: File
            TaskConfig("TempDecodeFileCleanTask")
            // TaskName: LarkKARemoteBuildTask
            // Des: 监听 KA 租户过期配置
            // Owner: 赵翔宇
            // Email: zhaoxiangyu.love@bytedance.com
            // Module: KA
            TaskConfig("LarkKARemoteBuildTask")
            // TaskName: KAUpgradeLaunchTask
            // Des: KA 升级埋点上报
            // Owner: 王元洵
            // Email: wangyuanxun@bytedance.com
            // Module: KA
            TaskConfig("KAUpgradeLaunchTask")
            // TaskName: PageInTask
            // Des: pageIn预加载
            // Owner: 黄立兴
            // Email: huanglx@bytedance.com
            // Module: Messenger
            TaskConfig("PageInTask")
            // TaskName: VEPreloadTask
            // Des: VE 预加载任务
            // Owner: 黄浩庭
            // Email: huanghaoting@bytedance.com
            // Module: Video
            TaskConfig("VEPreloadTask")
            // TaskName: SettingIdleTask
            // Des: Setting相关低优先级任务
            // Owner: 王元洵
            // Email: wangyuanxun@bytedance.com
            // Module: Platform
            TaskConfig("SettingIdleTask")
            // TaskName: UpdateUrgentNumTask
            // Des: 更新用户加急电话号码
            // Owner: 李自杰
            // Email: lizijie.lizj@bytedance.com
            // Module: Messenger
            TaskConfig("UpdateUrgentNumTask")
            // TaskName: EncryptionUpgradePredecessorTask
            // Des: 密钥升级前置流程
            // Owner: sunxingjian
            // Email: sunxingjian@bytedance.com
            // Module: S&C
            TaskConfig("EncryptionUpgradePredecessorTask")
            // TaskName: FileCryptoCleanTmpFileTask
            // Des: 加解密数据迁移临时文件清理
            // Owner: chenqqingchun
            // Email: chenqqingchun@bytedance.com
            // Module: S&C
            TaskConfig("FileCryptoCleanTmpFileTask")
    }
