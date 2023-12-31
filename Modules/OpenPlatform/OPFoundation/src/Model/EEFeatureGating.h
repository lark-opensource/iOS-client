//
//  EEFeatureGating.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/24.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/EMAFeatureGating.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  👉🏻 用于 EE 临时性 Bugfix 的 FG 配置 👈🏻
 *  👉🏻 该代码无需合入 Base 层 👈🏻
 *  👉🏻 需求请走标准开发及合入流程 👈🏻
 *  👉🏻 在合码完全完成后删除该文件 👈🏻
 */
extern NSString *const EEFeatureGatingKeyGadgetEnablePublishLog; // worker publish API 是否打印日志(高频日志治理，默认不开) https://bytedance.feishu.cn/docx/UXFvdrs6KoP3gIxmUaBcXiREnQe
extern NSString *const EEFeatureGatingKeyGadgetWebAppApiMonitorReport;
extern NSString *const EEFeatureGatingKeyGadgetComponentTextAreaSwitchable; /// 是否使用前端/native切换的textarea
extern NSString *const EEFeatureGatingKeyGadgetOpenAppBadge; // 应用角标功能fg
extern NSString *const EEFeatureGatingKeyGadgetDisablePluginManager; // fg:是否禁用API新版Pluginmanager
extern NSString *const EEFeatureGatingKeyGadgetEnableSlideExitOnHitDebugPoint; //小程序真机调试状态下，是否允许侧滑退出小程序（V4.2 发现 Lark 导航栏异常，这里做一下兜底切换）
extern NSString *const EEFeatureGatingKeyGadgetAPIUseJSSDKMonitor; //小程序api是否使用JSSDK埋点
extern NSString *const EEFeatureGatingKeyGadgetIos15InputKeyboardWakeUpAfterDelay; //ios15 input延迟拉取键盘 @doujian
extern NSString *const EEFeatureGatingKeyGadgetWebComponentCheckdomain; // wkwebviewcompontent组件加载url安全检查
extern NSString *const EEFeatureGatingKeyGadgetWebComponentIDEDisableCheckDomain;  // 开发者工具IDE中关闭小程序web-view安全域名校验配置是否可以同步到端上
extern NSString *const EEFeatureGatingKeyGadgetWebComponentDoubleCheck; // wkwebviewcompontent安全域名二次校验
extern NSString *const EEFeatureGatingKeyGadgetWebComponentDomainOpen; // wkwebviewcompontent拦截域名切为open
extern NSString *const EEFeatureGatingKeyGadgetWebComponentIgnoreInterrupted; // wkwebviewcompontent 忽略102错误
extern NSString *const EEFeatureGatingKeyGadgetWebComponentGlobalEnableURL; // wkwebviewcompontent组件放行所有url
extern NSString *const EEFeatureGatingKeyGadgetWorkerAPIUseJSSDKMonitor; //worker api是否使用JSSDK埋点
extern NSString *const EEFeatureGatingKeyGadgetEnableH5NativeBufferEncode; // 是否开启 H5 API nativebuffer 能力支持
extern NSString *const EEFeatureGatingKeyGadgetWorkerModuleDisable; //worker 功能开关
extern NSString *const EEFeatureGatingKeyGadgetWorkerCheckOnLaunchEnable; // 评论JSWorker是否需要在启动时检查更新
extern NSString *const EEFeatureGatingKeyGadgetNativeComponentEnableMap; // map使用新同层
extern NSString *const EEFeatureGatingKeyGadgetNativeComponentEnableVideo; // video使用新同层
extern NSString *const EEFeatureGatingKeyGadgetVideoMetalEnable; // video支持Metal
extern NSString *const EEFeatureGatingKeyGadgetVideoEnableCorrentRealClock; // video是否开启倍速时钟修复
extern NSString *const EEFeatureGatingKeyGadgetVideoDisableAutoPause; // video是否禁用离屏暂停功能
extern NSString *const EEFeatureGatingKeyGetUserInfoAuth; // getUserInfo用户授权fg
extern NSString *const EEFeatureGatingKeyGetAddAuthTextLength; // 临时加长授权弹窗文案显示长度
extern NSString *const EEFeatureGatingKeyNewScopeMapRule; // 小程序权限本地名称与服务器上保存的名称新的映射逻辑fg
extern NSString *const EEFeatureGatingKeyChooseLocationSupportWGS84; // chooseLocation是否支持wgs84类型坐标返回fg
extern NSString *const EEFeatureGatingKeyTransferMessageFormateConsistent; // break change - 双向通信api三端消息格式不一致对齐开关
extern NSString *const EEFeatureGatingKeyNativeComponentDisableShareHitTest;
extern NSString *const EEFeatureGatingKeyGadgetTabBarRelaunchFixDisable;
extern NSString *const EEFeatureGatingKeyEnableAppLinkPathReplace;
extern NSString *const EEFeatureGatingKeyBlockJSSDKUpdate;
extern NSString *const EEFeatureGatingKeyBlockJSSDKFixCopyBundleIssue;
extern NSString *const EEFeatureGatingKeyBridgeCallbackArrayBuffer; // api callback 支持 arraybuffer 类型
extern NSString *const EEFeatureGatingKeyBridgeFireEventArrayBuffer; // fireevent 支持 arraybuffer 类型
extern NSString *const EEFeatureGatingKeyFixMergePackageDownloadTask; // fix mergeDownloadTask not fire begun callback
extern NSString *const EEFeatureGatingKeyScopeBluetoothEnable; // 蓝牙API是否需要授权
extern NSString *const EEFeatureGatingKeyXScreenGadgetEnable;  // 开启小程序半屏的能力
extern NSString *const EEFeatureGatingKeyIGadgetPresentFrameFixEnable; // 修复Tabbar组件小程序在被Present时,webview高度可能不正确
extern NSString *const EEFeatureGatingKeyFixNavigationPushPosition; // 修复小程序由默认导航栏跳转自定义导航栏页面的动画时导航栏位置跳变问题 
extern NSString *const EEFeatureGatingKeyXscreenLayoutFixDisable; // 半屏导航栏布局适配，默认开启(不配置即开启)
extern NSString *const EEFeatureGatingKeyResetFrameFixDisable;  //修复在存在通知栏时,webview高度异常的问题(不配置即开启)
extern NSString *const EEFeatureGatingKeyNativeComponentKeyboardOpt;
extern NSString *const EEFeatureGatingKeyEvadeJSCoreDeadLock; // 将 JSEngine 释放移到子线程释放，规避在主线程释放 JSCore 有概率发生卡死问题
extern NSString *const EEFeatureGatingKeyBDPPiperRegisterOptDisable; // openplatform.api.bridge.register.opt.disable, 屏蔽BDPJSBridgeRegister注册的开关, 默认值是false, 表示优化打开.
extern NSString *const EEFeatureGatingKeyAPINetworkV1PMDisable; // openplatform.api.network.v1.pm.disable, 网络API v1走pluginmanager派发的逻辑禁用开关
extern NSString *const  EEFeatureGatingKeyGadgetTabBarRemoveFixDisable; //删除一个不存在的tab,增加报错。当前会返回成功

#define EEFeatureGating EMAFeatureGating

NS_ASSUME_NONNULL_END
