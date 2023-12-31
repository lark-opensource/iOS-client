//
//  OPGadgetContainerController+MultiTask.swift
//  OPGadget
//
//  Created by yinyuan on 2021/3/15.
//

import Foundation
import TTMicroApp
import LarkSuspendable
import LarkTab
import LKCommonsLogging
import LarkAppLinkSDK
import OPFoundation
import UniverseDesignIcon
import OPSDK
import LarkUIKit
import LarkKeepAlive
import LarkQuickLaunchInterface

private let logger = Logger.oplog(BDPAppContainerController.self, category: "Suspendable")

/// 小程序接入 Lark 多任务
///
/// 接入文档：https://bytedance.feishu.cn/wiki/wikcndNJcu1JC2rlAKA2B9IYTPb#
/// 需求文档：https://bytedance.feishu.cn/docs/doccnXBUpcw7EtchpYyYnZKkHUd
extension BDPAppContainerController: ViewControllerSuspendable {
    
    public var suspendID: String {
        let defaultID = ""
        // 唯一 ID 直接取应用 uniqueID 即可
        guard let uniqueID = uniqueID else {
            OPAssertionFailureWithLog("uniqueID is nil")
            return defaultID
        }
        return uniqueID.fullString
    }
    
    public var suspendTitle: String {
        // 返回多任务标题(一些极端情况下(本地缓存被清理)，降级为使用 appID 作为标题作为兜底避免显示为空)
        var defaultTitle = uniqueID?.appID ?? ""
        if Display.pad {
            // iPad下不需要默认标题
            defaultTitle = ""
        }
        guard let uniqueID = uniqueID else {
            OPAssertionFailureWithLog("uniqueID is nil")
            return defaultTitle
        }
        guard let common = BDPCommonManager.shared().getCommonWith(uniqueID) else {
            logger.info("common is nil")
            // 一些极端情况下，小程序可能被内存回收，这里无法拿到 common，降级为从本地缓存读取
            guard let localMeta = getLocalMeta(uniqueID: uniqueID) else {
                logger.error("localMeta not found")
                return defaultTitle
            }
            return localMeta.name
        }
        guard let model = OPUnsafeObject(common.model) else {
            logger.error("model is nil")
            return defaultTitle
        }
        guard let name = OPUnsafeObject(model.name) else {
            logger.error("name is nil")
            return defaultTitle
        }
        guard !name.isEmpty else {
            logger.error("name is empty")
            return defaultTitle
        }
        return name
    }
    
    public var suspendIcon: UIImage? {
        // 返回多任务icon
        return BundleResources.OPGadget.icon_app_outlined
    }
    
    public var suspendURL: String {
        // 返回多任务启动 URL
        let defaultURL = ""
        guard let uniqueID = uniqueID else {
            OPAssertionFailureWithLog("uniqueID is nil")
            return defaultURL
        }
        // 此处直接返回基本的 URL
        guard let url = GadgetAppLinkBuilder(uniqueID: uniqueID).buildURL()?.absoluteString else {
            logger.error("url is nil")
            return defaultURL
        }
        logger.info("return suspendURL:\(url)")
        return url
    }
    
    public var suspendParams: [String : AnyCodable] {
        // 指定启动场景值
        return [FromSceneKey.key: AnyCodable(FromScene.multi_task.rawValue)]
    }
    
    public var isWarmStartEnabled: Bool {
        // 不接入 MultiTask 提供的热启动机制，小程序自己管理热启动缓存
        false
    }
    
    public var analyticsTypeName: String {
        // 指定埋点数据类型
        return "gadget"
    }
    
    public var isViewControllerRecoverable: Bool {
        // 小程序自己管理VC生命周期，不需要由多任务框架持有 VC
        return false
    }
    
    public var isInteractive: Bool {
        // 小程序不需要支持滑动收入多任务
        return false
    }
    
    public var suspendGroup: SuspendGroup {
        return .gadget
    }
    
    public var suspendIconURL: String? {
        // 返回多任务图标
        guard let uniqueID = uniqueID else {
            OPAssertionFailureWithLog("uniqueID is nil")
            return nil
        }
        guard let common = BDPCommonManager.shared().getCommonWith(uniqueID) else {
            logger.info("common is nil")
            // 一些极端情况下，小程序可能被内存回收，这里无法拿到 common，降级为从本地缓存读取
            guard let localMeta = getLocalMeta(uniqueID: uniqueID) else {
                logger.error("localMeta not found")
                return nil
            }
            return localMeta.iconUrl
        }
        guard let model = OPUnsafeObject(common.model) else {
            logger.error("model is nil")
            return nil
        }
        guard let icon = OPUnsafeObject(model.icon) else {
            logger.error("icon is nil")
            return nil
        }
        guard !icon.isEmpty else {
            logger.error("icon is empty")
            return nil
        }
        return icon
    }
}

/// 接入 `TabContainable` 协议后，该页面可由用户手动添加至“底部导航” 和 “快捷导航” 上
extension BDPAppContainerController: TabContainable {

    /// 页面的唯一 ID，由页面的业务方自己实现
    ///
    /// - 同样 ID 的页面只允许收入到导航栏一次
    /// - 如果该属性被实现为 ID 恒定，SDK 在数据采集的时候会去重
    /// - 如果该属性被实现为 ID 变化（如自增），则会被 SDK 当成不同的页面采集到缓存，展现上就是在导航栏上出现多个这样的页面
    /// - 举个🌰
    /// - IM 业务：传入 ChatId 作为唯一 ID
    /// - CCM 业务：传入 objToken 作为唯一 ID
    /// - OpenPlatform（小程序 & 网页应用） 业务：传入应用的 uniqueID 作为唯一 ID
    /// - Web（网页） 业务：传入页面的 url 作为唯一 ID（为防止url过长，sdk 处理的时候会 md5 一下，业务方无感知
    public var tabID: String {
        // 未启动成功不记录到最近使用
        guard Display.pad || launchSuccess else {
            return ""
        }
        
        // 半屏模式不能被记录到最近
        guard !BDPXScreenManager.isXScreenMode(uniqueID) else {
            return ""
        }
        
        // 主导航不记录到最近使用
        guard !OPGadgetRotationHelper.isTabGadget(uniqueID) else {
            return ""
        }
        
        return uniqueID?.appID ?? ""
    }

    /// 页面所属业务应用 ID，例如：网页应用的：cli_123455
    ///
    /// - 如果 BizType == WEB_APP 的话 SDK 会用这个 BizID 来给 app_id 赋值
    ///
    /// 目前有些业务，例如开平的网页应用（BizType == WEB_APP），tabID 是传 url 来做唯一区分的
    /// 但是不同的 url 可能对应的应用 ID（BizID）是一样的，所以用这个字段来额外存储
    ///
    /// 所以这边就有一个特化逻辑：
    /// if(BizType == WEB_APP) { uniqueId = BizType + tabID, app_id = BizID}
    /// else { uniqueId = BizType+ tabID, app_id = tabID}
    public var tabBizID: String {
        return ""
    }
    
    /// 页面所属业务类型
    ///
    /// - SDK 需要这个业务类型来拼接 uniqueId
    ///
    /// 现有类型：
    /// - CCM：文档
    /// - MINI_APP：开放平台：小程序
    /// - WEB_APP ：开放平台：网页应用
    /// - MEEGO：开放平台：Meego
    /// - WEB：自定义H5网页
    public var tabBizType: CustomBizType {
        return .MINI_APP
    }
    
    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的图标（最近使用列表里面也使用同样的图标）
    /// - 如果后期最近使用列表里面要展示不同的图标需要新增一个协议
    public var tabIcon: CustomTabIcon {
        if let url = suspendIconURL {
            return .urlString(url)
        } else {
            return .iconName(.appOutlined)
        }
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的标题（最近使用列表里面也使用同样的标题）
    public var tabTitle: String {
        suspendTitle
    }

    /// 页面的 URL 或者 AppLink，路由系统 EENavigator 会使用该 URL 进行页面跳转
    ///
    /// - 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面
    /// - 对于Web（网页） 业务的话，这个值可能和 tabID 一样
    public var tabURL: String {
        suspendURL
    }
    
    /// 埋点统计所使用的类型名称
    ///
    /// 现有类型：
    /// - private 单聊
    /// - secret 密聊
    /// - group 群聊
    /// - circle 话题群
    /// - topic 话题
    /// - bot 机器人
    /// - doc 文档
    /// - sheet 数据表格
    /// - mindnote 思维导图
    /// - slide 演示文稿
    /// - wiki 知识库
    /// - file 外部文件
    /// - web 网页
    /// - gadget 小程序
    public var tabAnalyticsTypeName: String {
        return "gadget"
    }
    
    public func willMoveToTemporary() {
        if Display.pad && OPTemporaryContainerService.isGadgetTemporaryEnabled() {
            logger.info("willMoveToTemporary try to remove self from hierarchy")
            self.op_removeFromViewHierarchy(isCloseOtherSceneWhenOnlyHasIt: self.isCloseOtherSceneWhenOnlyHasIt, animated: false, complete: {}, failure: {_ in })
        }
    }
    
    public func willRemoveFromTemporary() {
        if Display.pad && OPTemporaryContainerService.isGadgetTemporaryEnabled() {
            logger.info("willRemoveFromTemporary try to remove self from hierarchy")
            self.op_removeFromViewHierarchy(isCloseOtherSceneWhenOnlyHasIt: self.isCloseOtherSceneWhenOnlyHasIt, animated: false, complete: {}, failure: {_ in })
        }
    }
    
    public func willCloseTemporary() {
        if Display.pad && OPTemporaryContainerService.isGadgetTemporaryEnabled() {
            logger.info("willCloseTemporary container unmount")
            OPApplicationService.current.getContainer(uniuqeID: uniqueID)?.unmount(monitorCode:GDMonitorCode.iPad_temporary_close)
        }
    }
    
    public var forceRefresh: Bool {
        return true
    }
}

extension BDPAppContainerController {
    
    // ViewControllerSuspendable:CustomNaviAnimation 小程序定制动画效果
    public func selfPushAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let uniqueID = uniqueID, SuspendManager.shared.contains(suspendID: uniqueID.fullString) {
            // 如果已经加入浮窗，则展示浮窗风格的动画，这里不定制动画
            return pushAnimationController(for: to)
        }
        let animation = BDPPresentAnimation()
        animation.style = .upDown
        animation.operation = .push
        return animation
    }

    // ViewControllerSuspendable:CustomNaviAnimation 小程序定制动画效果
    public func selfPopAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let uniqueID = uniqueID, SuspendManager.shared.contains(suspendID: uniqueID.fullString) {
            // 如果已经加入浮窗，则展示浮窗风格的动画，这里不定制动画
            return popAnimationController(for: from)
        }
        let animation = BDPPresentAnimation()
        animation.style = .upDown
        animation.operation = .pop
        return animation
    }
}

extension BDPAppContainerController {
    
    private func getLocalMeta(uniqueID: OPAppUniqueID) -> AppMetaProtocol? {
        logger.info("common is nil")
        // 一些极端情况下，小程序可能被内存回收，这里无法拿到 common，降级为从本地缓存读取
        guard let metaManager = BDPModuleManager(of: .gadget)
            .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModuleProtocol else {
            _ = OPError.error(monitorCode: OPSDKMonitorCode.has_no_module_manager, message: "has no meta module manager for gadget for app \(uniqueID)")
            OPAssertionFailureWithLog("has no meta module manager for gadget for app \(uniqueID)")
            return nil
        }
        return metaManager.getLocalMeta(with: MetaContext(uniqueID: uniqueID, token: nil))
    }
}

extension BDPAppContainerController {
    func markLaunchSuccess() {
        launchSuccess = true
    }
}

extension OPGadgetContainerController {
    func updateTemporary() {
        if OPTemporaryContainerService.isGadgetTemporaryEnabled() && self.isTemporaryChild {
            logger.info("updateTemporary title:\(self.suspendTitle) icon:\(self.tabIcon)")
            OPTemporaryContainerService.getTemporaryService().updateTab(self)
        }
    }
}

extension BDPAppContainerController: PagePreservable {
    public var pageScene: LarkQuickLaunchInterface.PageKeeperScene {
        get {
            if let currentMountData = OPApplicationService.current.getContainer(uniuqeID: uniqueID)?.containerContext.currentMountData as? OPGadgetContainerMountData {
                if let launcherFrom = currentMountData.launcherFrom, !launcherFrom.isEmpty {
                    return LarkQuickLaunchInterface.PageKeeperScene(rawValue: launcherFrom) ?? .normal
                }
            }
            return .normal
        }
        set(newValue) {
            
        }
    }
    
    public var pageID: String {
        return uniqueID?.appID ?? ""
    }
    
    public var pageType: LarkQuickLaunchInterface.PageKeeperType {
        return .littleapp
    }
    
    /// 能否被保活，默认为True，如果需要特殊不保活可以override
    ///
    /// - Returns: PageKeepError， 不为空则无法添加到队列
//    public func shouldAddToPageKeeper() -> PageKeepError? {
//        return nil
//    }

    /// 特殊场景下，业务不希望被移除，如后台播放等，交由业务方自行判断
    ///
    /// - Returns: PageKeepError， 不为空则无法从队列移除
    public func shouldRemoveFromPageKeeper() -> PageKeepError? {
        let keepAliveReason = BDPWarmBootManager().shouldKeepAlive(uniqueID)
        logger.info("PagePreservable shouldRemoveFromPageKeeper reason: \(keepAliveReason) uniqueID: \(uniqueID?.appID)")
        switch keepAliveReason {
        case BDPKeepAliveReasonBackgroundAudio:
            return .backgroundAudio
        case BDPKeepAliveReasonWhiteList:
            return .whiteList
        case BDPKeepAliveReasonLaunchConfig:
            return .customConfig
        case BDPKeepAliveReasonNone:
            return nil
        default:
            return nil
        }
    }

    public func willAddToPageKeeper() {
        
    }

    public func didAddToPageKeeper() {
        
    }

    public func willRemoveFromPageKeeper() {
        
    }

    public func didRemoveFromPageKeeper() {
        logger.info("PagePreservable didRemoveFromPageKeeper \(uniqueID?.appID)")
        BDPWarmBootManager().cleanCache(with: uniqueID)
    }
}
