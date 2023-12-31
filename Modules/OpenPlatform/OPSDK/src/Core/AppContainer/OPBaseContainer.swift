//
//  OPBaseContainer.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/16.
//

import Foundation
import LarkOPInterface
import LKCommonsLogging
import OPFoundation
import ECOProbe
import ECOInfra
import LarkSetting

fileprivate let logger = Logger.oplog(OPBaseContainer.self, category: "baseContainer")

@objcMembers
open class OPBaseContainer: OPNode, OPContainerProtocol {

    public let containerContext: OPContainerContext
    
    public let bridge: OPBridgeProtocol
    
    public private(set) var updater: OPContainerUpdaterProtocol?
    
    public private(set) var currentRenderSlot: OPRenderSlotProtocol?
    
    private var delegates: Array<WeakReference<OPContainerLifeCycleDelegate>> = []
        
    public private(set) var slotAttatched: Bool = false
    
    public private(set) var projectConfig: OPProjectConfig?

    public var sandbox: BDPSandboxProtocol?

    public var isSupportDarkMode: Bool {
        supportDarkMode()
    }

    open var runtimeVersion: String {
        OPAssertionFailureWithLog("runtimeVersion must implementation by subclass")
        return ""
    }

    public init(containerContext: OPContainerContext, updater: OPContainerUpdaterProtocol?) {
        logger.info("OPBaseContainer.init uniqueID:\(containerContext.uniqueID)")
        self.containerContext = containerContext
        self.updater = updater
        
        let bridge = OPBaseBridge()
        self.bridge = bridge
        super.init()
        bridge.delegate = self
    }
    
    deinit {
        logger.info("OPBaseContainer.deinit uniqueID:\(containerContext.uniqueID)")
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.deinit.threadprotect")) {
            if Thread.current.isMainThread {
                onDestroy(monitorCode: OPSDKMonitorCode.cancel)
            } else {
                DispatchQueue.main.sync {
                    onDestroy(monitorCode: OPSDKMonitorCode.cancel)
                }
            }
        } else {
            onDestroy(monitorCode: OPSDKMonitorCode.cancel)
        }
    }
    
    public func addLifeCycleDelegate(delegate: OPContainerLifeCycleDelegate) {
        delegates.append(WeakReference(value: delegate))
    }

    public func enumerateLifeCycleDelegate(body: (WeakReference<OPContainerLifeCycleDelegate>) -> Void) {
        delegates.forEach(body)
    }
}

/// 尝试流转生命周期状态，子类可以通过重写该方法实现流程定制
extension OPBaseContainer {
    
    /// 开始加载
    open func onLoad() {
        logger.info("onLoad. uniqueID:\(containerContext.uniqueID)")
        if containerContext.availability != .unload {
            // 只能是从 unload 状态流转过来，其他状态请调用 reload
            logger.warn("onLoad but unload already. uniqueID:\(containerContext.uniqueID)")
            return
        }
        
        containerContext.availability = .loading
        
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerDidLoad(container: self)
        }
    }
    
    /// 加载完成
    open func onReady() {
        logger.info("onReady. uniqueID:\(containerContext.uniqueID)")
        if containerContext.availability == .ready {
            logger.warn("onReady but ready already. uniqueID:\(containerContext.uniqueID)")
            return
        }
        
        containerContext.availability = .ready
        
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerDidReady(container: self)
        }
    }
    
    /// 加载失败
    open func onFail(error: OPError) {
        logger.info("OPBaseContainer.onFail uniqueID: \(containerContext.uniqueID) error: \(error)")
        if containerContext.availability == .failed {
            logger.warn("OPBaseContainer.onFail uniqueID: \(containerContext.uniqueID) msg: OPBaseContainer already failed.")
            return
        }
        
        containerContext.availability = .failed
        
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerDidFail(container: self, error: error)
        }
    }
    
    /// 卸载
    open func onUnload(monitorCode: OPMonitorCode) {
        logger.info("onUnload. uniqueID:\(containerContext.uniqueID), monitorCode: \(monitorCode)")
        if containerContext.availability == .unload {
            logger.warn("onUnload but unload already. uniqueID:\(containerContext.uniqueID)")
            return
        }
        
        containerContext.availability = .unload
        
        projectConfig = nil
        
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerDidUnload(container: self)
        }
    }
    
    /// 加载到视图
    open func onMount(data: OPContainerMountDataProtocol, renderSlot: OPRenderSlotProtocol) {
        logger.info("onMount. uniqueID:\(containerContext.uniqueID) scene:\(data.scene)")
        
        // 设置 initData
        if self.containerContext.firstMountData == nil {
            self.containerContext.firstMountData = data
        }
        self.containerContext.currentMountData = data
        
        // 设置 currentRenderSlot
        currentRenderSlot = renderSlot
        
        containerContext.mountState = .mounted
        
        // 如果还未开始加载，则先开始加载
        if containerContext.availability == .unload {
            onLoad()
        }
        
        if onBindSlot(renderSlot: renderSlot) {
            renderSlot.delegate?.onRenderAttatched(renderSlot: renderSlot)
        }
        
        // 更新可见性
        checkAndUpdateVisibility()
        
    }
    
    /// 从视图卸载
    open func onUnmount(monitorCode: OPMonitorCode) {
        logger.info("onUnmount. uniqueID:\(containerContext.uniqueID)")
        
        containerContext.mountState = .unmount
        if let currentRenderSlot = currentRenderSlot {
            if onUnbindSlot(renderSlot: currentRenderSlot) {
                currentRenderSlot.delegate?.onRenderRemoved(renderSlot: currentRenderSlot)
            }
        }
        
        // 更新可见性
        checkAndUpdateVisibility()
    }
    
    open func removeTemporaryTab() {
        
    }
    
    open func onReload(monitorCode: OPMonitorCode) {
        logger.info("onReload. uniqueID:\(containerContext.uniqueID) monitorCode:\(monitorCode)")
        containerContext.isReloading = true
        
        let mountState = containerContext.mountState
        let mountData = containerContext.currentMountData
        let renderSlot = currentRenderSlot
        
        // 需要先卸载
        if containerContext.availability != .unload {
            onUnload(monitorCode: monitorCode)
        }
        
        // 重置状态
        containerContext.availability = .unload
        
        // TODO: 小程序需要延迟一下等相关回收完成（主要与小程序VC退出动画和清理逻辑有关），然后才能再开始重新加载，这里先暴力等一下（沿用原小程序逻辑）, 后续考虑采用完善的方案支持
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 再重新加载
            if mountState == .mounted,
               let mountData = mountData,
               let renderSlot = renderSlot,
               self.containerContext.mountState != .mounted {
                // 需要重新 Mount
                self.onMount(data: mountData, renderSlot: renderSlot)
            } else {
                // 需要重新 Load
                if self.containerContext.availability != .ready {
                    self.onLoad()
                }
            }
            
            self.containerContext.isReloading = false
        }
    }
    
    open func onDestroy(monitorCode: OPMonitorCode) {
        logger.info("onDestroy. uniqueID:\(containerContext.uniqueID)")
        if containerContext.isReloading {
            assertionFailure("onDestroy is not allowed during reloading.")
            logger.error("onDestroy is not allowed during reloading. uniqueID:\(containerContext.uniqueID)")
            return
        }
        containerContext.availability = .destroyed
        
        if containerContext.mountState != .unmount {
            onUnmount(monitorCode: monitorCode)
        }
        
        if let currentRenderSlot = currentRenderSlot {
            _ = onUnbindSlot(renderSlot: currentRenderSlot)
        }
        
        if containerContext.availability != .unload {
            onUnload(monitorCode: monitorCode)
        }
        
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerDidDestroy(container: self)
        }
    }
    
    open func onShow() {
        logger.info("onShow. uniqueID:\(containerContext.uniqueID)")
        if containerContext.visibility == .visible {
            logger.warn("onShow but visible already. uniqueID:\(containerContext.uniqueID)")
            return
        }
        
        containerContext.visibility = .visible
        
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerDidShow(container: self)
        }
    }
    
    
    /// 按照 renderSlot 协议绑定视图
    /// - Parameter renderSlot: renderSlot
    /// - Returns: 是否完成绑定
    open func onBindSlot(renderSlot: OPRenderSlotProtocol) -> Bool {
        logger.info("onBindSlot. uniqueID:\(containerContext.uniqueID)")
        // 子类重写该方法需要 return super.onBindSlot
        slotAttatched = true
        
        // 更新可见性
        checkAndUpdateVisibility()
        
        return true
    }
    
    
    /// 取消 renderSlot 协议的视图绑定
    /// - Parameter renderSlot: renderSlot
    /// - Returns: 是否已取消绑定
    open func onUnbindSlot(renderSlot: OPRenderSlotProtocol) -> Bool {
        logger.info("onUnbindSlot. uniqueID:\(containerContext.uniqueID)")
        // 子类重写该方法需要 return super.onUnbindSlot
        slotAttatched = false
        
        // 更新可见性
        checkAndUpdateVisibility()
        
        return true
    }
    
    open func onHide() {
        logger.info("onHide. uniqueID:\(containerContext.uniqueID)")
        if containerContext.visibility == .invisible {
            logger.warn("onHide but invisible already. uniqueID:\(containerContext.uniqueID)")
            return
        }
        
        containerContext.visibility = .invisible
        
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerDidHide(container: self)
        }
    }
    
    open func onPause() {
        logger.info("onPause. uniqueID:\(containerContext.uniqueID)")
        if containerContext.activeState == .inactive {
            logger.warn("onPause but inactive already. uniqueID:\(containerContext.uniqueID)")
            return
        }
        
        containerContext.activeState = .inactive
        
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerDidPause(container: self)
        }
    }
    
    open func onResume() {
        logger.info("onResume. uniqueID:\(containerContext.uniqueID)")
        if containerContext.activeState == .active {
            logger.warn("onResume but active already. uniqueID:\(containerContext.uniqueID)")
            return
        }
        
        containerContext.activeState = .active
        
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerDidResume(container: self)
        }
    }

    /// 是否支持 dark mode，子类按需复写
    open func supportDarkMode() -> Bool {
        return false
    }

    open func onThemeChange(_ theme: String) {
        OPAssertionFailureWithLog("onThemeChange must implementation by subclass")
    }

    open func onSendEventToBridge(
        eventName: String,
        params: [AnyHashable : Any]?,
        callback: OPBridgeCallback?) throws {
        logger.info("onSendEventToBridge. uniqueID:\(containerContext.uniqueID) eventName:\(eventName)")
        throw OPSDKMonitorCode.unknown_error.error(message: "send event to bridge not supported")
    }
    
    // 更新 Visibility
    open func checkAndUpdateVisibility() {
        if containerContext.mountState == .mounted, let currentRenderSlot = currentRenderSlot, !currentRenderSlot.hidden, slotAttatched {
            if containerContext.visibility != .visible {
                onShow()
                checkAndUpdateActiveState()
            }
        } else {
            if containerContext.visibility != .invisible {
                onHide()
                checkAndUpdateActiveState()
            }
        }
    }
    
    // 更新 ActiveState
    open func checkAndUpdateActiveState() {
        // App 前台 & Container 可见
        if containerContext.visibility == .visible, containerContext.applicationContext.applicationServiceContext.applicationActive {
            if containerContext.activeState != .active {
                onResume()
            }
        } else {
            if containerContext.activeState != .inactive {
                onPause()
            }
        }
    }
    
    open func onConfigReady(projectConfig: OPProjectConfig) {
        self.projectConfig = projectConfig
        // 对外发送生命周期事件
        delegates.forEach { (weakDelegate) in
            weakDelegate.value?.containerConfigDidLoad(container: self, config: projectConfig)
        }
    }
    
    /// 在执行 mount 前是否需要先 unmount，默认需要
    open func needUnmountBeforeMount(data: OPContainerMountDataProtocol, renderSlot: OPRenderSlotProtocol) -> Bool {
        return true
    }
}

// MARK: OPContainerProtocol 方法实现
extension OPBaseContainer {
    
    /// 本方法为对外接口的实现，只对外负责，不对内负责，核心实现在私有接口 onMount 内
    public func mount(data: OPContainerMountDataProtocol, renderSlot: OPRenderSlotProtocol) {
        logger.info("mount. uniqueID:\(containerContext.uniqueID)")
        guard containerContext.availability != .destroyed else {
            // 已销毁对象，不再允许调用
            OPAssertionFailureWithLog("a destroyed container should not be called any more")
            return
        }
        
        // 外部调用如果已 mount 先调用 onUnmount
        if containerContext.mountState == .mounted, needUnmountBeforeMount(data: data, renderSlot: renderSlot) {
            onUnmount(monitorCode: OPSDKMonitorCode.cancel)
        }
        
        onMount(data: data, renderSlot: renderSlot)
    }
    
    /// 本方法为对外接口的实现，只对外负责，不对内负责，核心实现在私有接口 onUnmount 内
    public func unmount(monitorCode: OPMonitorCode) {
        logger.info("unmount. uniqueID:\(containerContext.uniqueID)")
        guard containerContext.availability != .destroyed else {
            // 已销毁对象，不再允许调用
            OPAssertionFailureWithLog("a destroyed container should not be called any more")
            return
        }
        
        onUnmount(monitorCode: monitorCode)
    }
    
    /// 本方法为对外接口的实现，只对外负责，不对内负责，核心实现在私有接口 onReload 内
    public func reload(monitorCode: OPMonitorCode) {
        logger.info("reload. uniqueID:\(containerContext.uniqueID)")
        guard containerContext.availability != .destroyed else {
            // 已销毁对象，不再允许调用
            OPAssertionFailureWithLog("a destroyed container should not be called any more")
            return
        }
        
        onReload(monitorCode: monitorCode)
    }
    
    /// 本方法为对外接口的实现，只对外负责，不对内负责
    public func notifyPause() {
        logger.info("notifyPause. uniqueID:\(containerContext.uniqueID)")
        guard containerContext.availability != .destroyed else {
            // 已销毁对象，不再允许调用
            OPAssertionFailureWithLog("a destroyed container should not be called any more")
            return
        }
        
        checkAndUpdateActiveState()
    }
    
    /// 本方法为对外接口的实现，只对外负责，不对内负责
    public func notifyResume() {
        logger.info("notifyResume. uniqueID:\(containerContext.uniqueID)")
        guard containerContext.availability != .destroyed else {
            // 已销毁对象，不再允许调用
            OPAssertionFailureWithLog("a destroyed container should not be called any more")
            return
        }
        
        checkAndUpdateActiveState()
    }
    
    /// 本方法为对外接口的实现，只对外负责，不对内负责
    public func notifySlotShow() {
        logger.info("notifySlotShow. uniqueID:\(containerContext.uniqueID)")
        guard containerContext.availability != .destroyed else {
            // 已销毁对象，不再允许调用
            OPAssertionFailureWithLog("a destroyed container should not be called any more")
            return
        }
        
        // 更新可见性
        currentRenderSlot?.hidden = false
        checkAndUpdateVisibility()
    }
    
    /// 本方法为对外接口的实现，只对外负责，不对内负责
    public func notifySlotHide() {
        logger.info("notifySlotHide. uniqueID:\(containerContext.uniqueID)")
        guard containerContext.availability != .destroyed else {
            // 已销毁对象，不再允许调用
            OPAssertionFailureWithLog("a destroyed container should not be called any more")
            return
        }
        
        // 更新可见性
        currentRenderSlot?.hidden = true
        checkAndUpdateVisibility()
    }

    /// 本方法为对外接口的实现，只对外负责，不对内负责
    public func notifyThemeChange(theme: String) {
        onThemeChange(theme)
    }
    
    /// 本方法为对外接口的实现，只对外负责，不对内负责，核心实现在私有接口 onDestroy 内
    public func destroy(monitorCode: OPMonitorCode) {
        logger.info("destroy. uniqueID:\(containerContext.uniqueID)")
        guard containerContext.availability != .destroyed else {
            // 已销毁
            logger.warn("destroy but destroyed already. uniqueID:\(containerContext.uniqueID)")
            return
        }
        if containerContext.isReloading {
            assertionFailure("destroy is not allowed during reloading.")
            logger.error("destroy is not allowed during reloading. uniqueID:\(containerContext.uniqueID)")
            return
        }
        onDestroy(monitorCode: monitorCode)
    }
}

extension OPBaseContainer: OPBaseBridgeDelegate {
    
    public func sendEventToBridge(
        eventName: String,
        params: [AnyHashable : Any]?,
        callback: OPBridgeCallback?) throws {
        try onSendEventToBridge(eventName: eventName, params: params, callback: callback)
    }
    
}

// 可见性计算
extension OPBaseContainer {
    
    public override func prepareEventContext(context: OPEventContext) {
        super.prepareEventContext(context: context)
        
        // 注入 Context
        context.containerContext = containerContext
        context.bridge = bridge
        context.presentBasedViewController = currentRenderSlot?.delegate?.currentViewControllerForPresent()
        context.navigationController = currentRenderSlot?.delegate?.currentNavigationControllerForPush()
    }
    
}

extension OPBaseContainer {
    
    public override var description: String {
        "OPBaseContainer(\(containerContext.uniqueID)"
    }
}
