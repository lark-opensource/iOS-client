//
//  ABTestSetupTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import AppContainer
import BootManager
import RunloopTools
import LarkAccountInterface
import BDABTestSDK
import RangersAppLog
import LarkSetting
import LarkBGTaskScheduler
import LKCommonsTracker
import LarkContainer

final class ABTestSetupTask: FlowBootTask, Identifiable { // Global
    static var identify = "ABTestSetupTask"

    override var delayScope: Scope? { return .container }

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        self.registABTest()
    }

    func registABTest() {
        typealias ABDelegate = ABTestSetupTask
        guard FeatureGatingManager.shared.featureGatingValue(with: "tt_ab_test") else { return }
        /// Spotlight ABTest
        ABTestSetupTask.registerSpotlightABTest()

        /// TBD: 下沉ABTest胶水库，这里改成由业务注册注入机制
        /// UserGrowth ABTest
        ABTestSetupTask.registerUserGrowthABTest()
        /// 引擎预加载 ABTest
        ABTestSetupTask.registerGadgetABTest()
        /// BGTask ABTest
        ABTestSetupTask.registerBGTaskABTest()
        // 公司圈评论外漏ABTest
        ABTestSetupTask.registerMomentsFeedExposeCommentABTest()
        // iOS发送图片默认转码webp
        ABTestSetupTask.registerSendImageConvertToWebpABTest()
        // iOS IM 播放器卡顿率置换实验
        ABTestSetupTask.registerVideoEngineABTest()
        // iOS 视频发送相关实验
        ABTestSetupTask.registerVideoMessageABTest()
        // 拉流协议 ABTest
        ABTestSetupTask.registerLarkLiveQuicTest()
        // iOS 图片库模糊查找耗时实验
        ABTestSetupTask.registerByteWebImageFuzzyCacheABTest()
        // iOS 图片库自研HEIF解码器实验
        ABTestSetupTask.registerByteWebImageLibttheifABTest()
        // 上传头像使用 WebP 格式上传实验
        ABTestSetupTask.registerAvatarUploadWebpABTest()
        // 加载头像使用 HEIC 格式实验
        ABTestSetupTask.registerAvatarDownloadHeicABTest()
        //小程序部分场景预加载业务小程序实验
        ABTestSetupTask.registerGadgetPrerunABTest()
        // 视频透传实验
        ABTestSetupTask.registerVideoPassthroughABTest()
        // 图片预加载实验
        ABTestSetupTask.registerImagePreloadABTest()
        // 文档预加载任务支持队列优先级
        ABTestSetupTask.registerDocsPreloadPriorityABTest()
        // 文档预加载任务先进后出
        ABTestSetupTask.registerDocsPreloadInsertPositionABTest()
        // 文档预加载任务持久化
        ABTestSetupTask.registerDocsPreloadArchedTaskABTest()
        // 文档预加载队列优先级
        ABTestSetupTask.registerDocsPreloadQueueABTest()
        // 文档预加载webview个数动态调整
        ABTestSetupTask.registerDocsPreloadWebViewCountABTest()
        // 预加载框架配置
        ABTestSetupTask.registerPreloadEnable()
        // 运行时lite配置
        ABTestSetupTask.registerLiteEnable()
        // 验证Feed拉取优化的AB实验
        ABTestSetupTask.registerFetchFeedEnable()
        // 降级框架实验
        ABTestSetupTask.registerDowngradeABTest()
        // 文档预测实验
        ABTestSetupTask.registerDocsForecastEnable()
        // SSR预加载率优化
        ABTestSetupTask.registerFetchSSRBeforeRenderABTest()
        //HMD功耗优化
        ABTestSetupTask.registerHMDPowerOptimizeEnable()
        // iOS文档预加载精准率实验
        ABTestSetupTask.registerDocsDisablePreloadSource()
        // 发出设置完成通知，注册完实验之后才能取到 cache 值
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Tracker.LKExperimentDataDidRegister), object: nil)
    }

    static private func registerBGTaskABTest() {
        let owner = "machao.mc"
        let desc = "BGTask 性能实验，用于描述BGTask开启对Lark性能的影响，为后续BGTask优化工作做准备。"

        let exp = BDABTestBaseExperiment(key: BGTaskConfig.key,
                                         owner: owner,
                                         description: desc,
                                         defaultValue: "",
                                         valueType: .string,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerUserGrowthABTest() {
        let key = "invite_member_channel_adjust"
        let owner = "caimengjie"
        let desc = "邀请成员分流页面调整"
        let defaultValue = ""

        let exp = BDABTestBaseExperiment(key: key,
                                         owner: owner,
                                         description: desc,
                                         defaultValue: defaultValue,
                                         valueType: .string,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerGadgetABTest() {
        let gadgetEnginePreloadABTestKey = "preload"
        let gadgetEnginePreloadABTestOwner = "machao.mc"
        let gadgetEnginePreloadABTestDesc = "对小程序框架的预加载进行 AB 实验"
        let gadgetEnginePreloadABTestDefaultValue = ["use": true]

        let exp = BDABTestBaseExperiment(key: gadgetEnginePreloadABTestKey,
                                         owner: gadgetEnginePreloadABTestOwner,
                                         description: gadgetEnginePreloadABTestDesc,
                                         defaultValue: gadgetEnginePreloadABTestDefaultValue,
                                         valueType: .dictionary,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerSpotlightABTest() {
        let owner = "shuxiang"
        let description = "在新用户 onboarding 流程中，通过修改 spotlight 中介绍 workplace 的文案，吸引用户使用 workplace 功能"
        let exp = BDABTestBaseExperiment(key: "spotlight_workplace",
                                         owner: owner,
                                         description: description,
                                         defaultValue: ["version": ""],
                                         valueType: .dictionary,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerMomentsFeedExposeCommentABTest() {
       let owner = "jiaxiao.shawn"
       let description = "公司圈评论外漏"
       let exp = BDABTestBaseExperiment(key: "moments_feed_expose_comment",
                                        owner: owner,
                                        description: description,
                                        defaultValue: 0,
                                        valueType: .number,
                                        isSticky: true)
       BDABTestManager.register(exp)
   }

    static private func registerVideoEngineABTest() {
        let owner = "lichen"
        let description = "iOS IM 播放器卡顿率置换实验"
        let defaultValue: [String: Any] = [
            "mdl": [:],
            "engine": [:],
            "preload": [:]
        ]
        let exp = BDABTestBaseExperiment(key: "im_video_player_ab_config",
                                         owner: owner,
                                         description: description,
                                         defaultValue: defaultValue,
                                         valueType: .dictionary,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerVideoMessageABTest() {
        let owner = "lichen"
        let description = "iOS IM 视频发送相关实验"
        let defaultValue: [String: Any] = [
            "compress": [:],
            "send": [:],
            "ve": [:],
            "compress_new": [:],
            "cover": [:]
        ]
        let exp = BDABTestBaseExperiment(key: "ve_synthesis_settings_ab_config",
                                         owner: owner,
                                         description: description,
                                         defaultValue: defaultValue,
                                         valueType: .dictionary,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerSendImageConvertToWebpABTest() {
        let owner = "kangsiwan"
        let description = "iOS发送图片默认转码webp"
        let exp = BDABTestBaseExperiment(key: "convert_to_webp",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerLarkLiveQuicTest() {
        let owner = "yangyao.wildyao"
        let desc = "quic拉流"

        let exp = BDABTestBaseExperiment(key: "lark_live_use_quic",
                         owner: owner,
                         description: desc,
                         defaultValue: 0,
                         valueType: .number,
                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerByteWebImageFuzzyCacheABTest() {
        let owner = "huanghaoting"
        let description = "iOS 图片库模糊查找耗时实验"
        let exp = BDABTestBaseExperiment(key: "byte_web_image_fuzzy_cache",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerByteWebImageLibttheifABTest() {
        let owner = "huanghaoting"
        let description = "iOS 图片库自研HEIF解码器实验"
        let exp = BDABTestBaseExperiment(key: "core_bytewebimage_libttheif",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerAvatarUploadWebpABTest() {
        let owner = "huanghaoting"
        let description = "上传头像使用 WebP 格式上传实验"
        let exp = BDABTestBaseExperiment(key: "messenger_avatar_upload_webp",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerAvatarDownloadHeicABTest() {
        let owner = "huanghaoting"
        let description = "加载头像使用 HEIC 格式实验"
        let exp = BDABTestBaseExperiment(key: "messenger_avatar_download_heic",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerGadgetPrerunABTest() {
        let owner = "chenmengqi.1024"
        let description = "小程序部分场景预加载业务信息实验"
        let exp = BDABTestBaseExperiment(key: "gadget_prerun",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerVideoPassthroughABTest() {
        let owner = "lichen.arthur"
        let description = "视频透传实验"
        let exp = BDABTestBaseExperiment(key: "messenger_video_passthrough",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerImagePreloadABTest() {
        let owner = "huanghaoting"
        let description = "图片预加载实验"
        let exp = BDABTestBaseExperiment(key: "image_preload_enable",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerDocsPreloadPriorityABTest() {
        let owner = "guoxinyi.4pang"
        let description = "文档预加载任务优先级实验"
        let exp = BDABTestBaseExperiment(key: "docs_preload_priority_enable_ios",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerDocsPreloadInsertPositionABTest() {
        let owner = "guoxinyi.4pang"
        let description = "文档预加载任务插入队列位置实验"
        let exp = BDABTestBaseExperiment(key: "docs_preload_filo_enable_ios",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerDocsPreloadArchedTaskABTest() {
        let owner = "guoxinyi.4pang"
        let description = "文档预加载任务持久化实验"
        let exp = BDABTestBaseExperiment(key: "docs_preload_arched_enable_ios",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerDocsPreloadQueueABTest() {
        let owner = "guoxinyi.4pang"
        let description = "文档预加载队列优先级优化"
        let exp = BDABTestBaseExperiment(key: "docs_preload_queue_priority_enable",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerDocsPreloadWebViewCountABTest() {
        let owner = "guoxinyi.4pang"
        let description = "文档预加载webview个数优化"
        let exp = BDABTestBaseExperiment(key: "docs_preload_webview_count_enable",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerPreloadEnable() {
        let owner = "huanglx"
        let description = "预加载框架是否开启，验证预加载框架对性能和预加载指标的影响"
        let exp = BDABTestBaseExperiment(key: "lark_preload_enable",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerLiteEnable() {
        let owner = "huanglx"
        let description = "运行时lite是否开启，验证预运行时lite对性能指标的影响"
        let exp = BDABTestBaseExperiment(key: "lark_lite_enable",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerFetchFeedEnable() {
        let owner = "yangjing.sniper0"
        let description = "验证Feed拉取优化的AB实验"
        let exp = BDABTestBaseExperiment(key: "iOSEnableFeedOptimize",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }

    static private func registerDowngradeABTest() {
         let owner = "songlongbiao"
         let description = "降级框架相关实验"
         let defaultValue: [String: Any] = [
             "normal_level": [],
             "middle_level": [],
             "high_level": []
         ]
         let exp = BDABTestBaseExperiment(key: "lark_ios_downgrade",
                                          owner: owner,
                                          description: description,
                                          defaultValue: defaultValue,
                                          valueType: .dictionary,
                                          isSticky: true)
         BDABTestManager.register(exp)
     }
    
    static private func registerDocsForecastEnable() {
        let owner = "lijuyou"
        let description = "文档用户行为预测，提升文档打开速度，降低资源消耗"
        let exp = BDABTestBaseExperiment(key: "docs_forecast_enable",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerHMDPowerOptimizeEnable() {
        let owner = "yuanzhangjing"
        let description = "Heimdallr SDK 功耗优化"
        let exp = BDABTestBaseExperiment(key: "optimize_hmd_power_enable",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerFetchSSRBeforeRenderABTest() {
        let owner = "huangzhikai.hzk"
        let description = "提前拉取SSR，进行SSR预加载优化"
        let exp = BDABTestBaseExperiment(key: "docs_fetch_ssr_before_render_enable",
                                         owner: owner,
                                         description: description,
                                         defaultValue: 0,
                                         valueType: .number,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
    
    static private func registerDocsDisablePreloadSource() {
        let owner = "liujinwei"
        let description = "CCM文档预加载精准率实验-iOS"
        let exp = BDABTestBaseExperiment(key: "ccm_preload_source_disabled",
                                         owner: owner,
                                         description: description,
                                         defaultValue: ["default": []],
                                         valueType: .dictionary,
                                         isSticky: true)
        BDABTestManager.register(exp)
    }
}

final class UpdateABTestTask: UserFlowBootTask, Identifiable {
    static let identify = "UpdateABTestTask"

    override func execute() throws {
        try userResolver.resolve(assert: ABTestLaunchDelegate.self)
            .updateABTestExperimentData()
    }
}
