//
//  EditorsPool.swift
//  Alamofire
//
//  Created by Huang JinZhu on 2018/8/6.
//

import UIKit
import RxSwift
import SKFoundation
import SKCommon
import SKResource
import SKUIKit
import EENavigator
import Heimdallr
import LKCommonsTracker
import SpaceInterface
import SKInfra
import LarkPerf
import BootManager
import LarkContainer


enum EditorType {
    case webEditor
    case nativeEditor
}

enum DropReason: String {
    case terminated
    case timeout
    case enterBackground
    case nonResponsive
    case notPreloadReay
    case memoryWarning
    case tooMany
}

final public class EditorsPool<ResuableItem: DocReusableItem>: NSObject {
    typealias EditorCreation = (EditorType) -> ResuableItem
    private(set) var items: [ResuableItem] = [] //缓存池中的view Items
    private var maxCount = 1
    private let userResolver: UserResolver
    private var maxUsedCountPerItem = 5
    private let itemRecorder: SpaceWebViewRecorder<ResuableItem> = SpaceWebViewRecorder<ResuableItem>() //所有WebView，包括缓存池和正在使用的
    private let editorCreation: EditorCreation
    var isInVCFollow: Bool = false
    public private(set) var continuousFailCount: UInt = 0 //连续失败次数
    var resetWKProcessPoolPolicy = 0
    var recoveryWebViewCount: Int = 0
    private lazy var limitMemorySize: Int64 = {
        return Int64(hmd_getDeviceMemoryLimit() / 1048576)
    }()
    
    var isInForeground = true {
        didSet {
            if oldValue == false, isInForeground == true {
                // 在iOS13版本如果命中的ccm.doc.foreground_switch_logic_enable 为 false，不走相关流程
                if #available(iOS 13, *) {
                    if #available(iOS 14, *) {
                    } else if !LKFeatureGating.foregroundSwitchLogicEnable {
                        DocsLogger.info("enter foreground", component: LogComponents.editorPool)
                        return
                    }
                }
                DocsLogger.info("enter foreground，fill pool", component: LogComponents.editorPool)
                tryFillEditorPool(delay: 0)
            } else if oldValue == true, isInForeground == false {
                DocsLogger.info("enter background，clean pool", component: LogComponents.editorPool)
                keepMinimumEditor()
            }
        }
    }

    init(poolMaxCount: Int, maxUsedPerItem: Int, userResolver: UserResolver, editorCreation: @escaping EditorCreation) {
        spaceAssert(poolMaxCount > 0, "pool max Count < 0")
        spaceAssert(maxUsedPerItem > 0, "max used per item < 0")
        self.maxCount = poolMaxCount
        self.userResolver = userResolver
        self.maxUsedCountPerItem = maxUsedPerItem
        self.editorCreation = editorCreation
        super.init()
        let info = ["maxUsedPerItem": maxUsedPerItem, "poolMaxCount": poolMaxCount]
        DocsLogger.info("editorPool init:", extraInfo: info, error: nil, component: LogComponents.editorPool)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeModule(_:)),
                                                       name: Notification.Name(rawValue: "byteview.didChangeClientMutex"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiverOpenDocsEnd(info:)), name: Notification.Name.OpenFileRecord.AutoOpenEnd, object: nil)
        //slardar memory warning from Lark iOS 内存压力监听方案: https://bytedance.feishu.cn/wiki/wikcnBptylmllRsEZDSQ0WkzcFg
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryLevelNotification(_:)), name: NSNotification.Name(rawValue: SKMemoryMonitor.memoryWarningNotification), object: nil)
    }
    
    public static func docxDynamicWebViewCountEnable() -> Bool {
        guard UserScopeNoChangeFG.GXY.docxDynamicWebViewCountEnable,
              SKDisplay.phone,
              (MobileClassify.mobileClassType == .highMobile || MobileClassify.mobileClassType == .middleMobile) else {
            return false
        }
#if DEBUG
        return true
#else
        if let abEnable = Tracker.experimentValue(key: "docs_preload_webview_count_enable", shouldExposure: true) as? Int, abEnable == 1 {
            return true
        }
        return false
#endif
    }
    
    @objc
    private func didReceiveMemoryLevelNotification(_ notification: Notification) {
        guard EditorsPool.docxDynamicWebViewCountEnable() else {
            return
        }
        let userInfo = notification.userInfo
        // 如果在内存高水位(4)以上的level,需要释放多出来的webview
        if let flag = userInfo?["type"] as? Int32, flag >= OpenAPI.docs.memoryWarningLevel {
            DocsLogger.warning("receive MemoryLevel change: \(flag)", component: LogComponents.editorPool)
            DispatchQueue.safetyAsyncMain { [weak self] in
                guard let self = self else { return }
                DocsLogger.info("pool drain start remove one more items: \(self.items.count)", component: LogComponents.editorPool)
                // 先移除模版没有加载好的
                if self.items.count > self.maxCount {
                    let unReady = self.items.filter { $0.hasPreloadSomething == false}
                    for i in 0..<min(self.items.count - self.maxCount, unReady.count) {
                        let item = unReady[i]
                        self.dropEditor(item, for: .memoryWarning)
                    }
                }
                DocsLogger.info("after remove unready current total:\(self.itemRecorder.count), \(self.items.count) editors in pool", component: LogComponents.editorPool)
                // 再找复用次数较多的
                if self.items.count > self.maxCount {
                    let sorted = self.items.sorted { $0.usedCounter > $1.usedCounter }
                    for i in 0..<(self.items.count - self.maxCount)  {
                        let item = sorted[i]
                        self.dropEditor(item, for: .memoryWarning)
                    }
                }
                DocsLogger.info("last drain current total:\(self.itemRecorder.count), \(self.items.count) editors in pool", component: LogComponents.editorPool)
            }
        }
    }

    public func dequeueReuseableItem(for type: DocsType) -> ResuableItem {
        if type == .docX, userResolver.docs.editorManager?.nativeDocxEnable == true {
            // native编辑器
            return editorCreation(.nativeEditor)
        }
        if !DocsSDK.isBeingTest {
            assert(GeckoPackageManager.shared.hasConfigured)
        }
        defer {
            // 打开文档后，写死2s填充复用池不太合理，因为有可能当前文档还没有打开，会跟当前文档争夺资源。iPad维持旧逻辑
            if SKDisplay.pad {
                tryFillEditorPool(delay: 2.0)
            }
        }
        DocsLogger.info("====dequeue WebView's count \(self.itemRecorder.count) / EditorsPool's count \(self.items.count) ====", component: LogComponents.editorPool)
        //先从pool里找到可以用的
        if let editor = getReuseableEditorFor(type: type) {
            removeEditorFromPool(editor)
            DocsLogger.info("get editor \(editor.editorIdentity) from pool, useCount:\(editor.usedCounter)", component: LogComponents.editorPool)
            DocsLogger.info("reuseable current total:\(itemRecorder.count), \(items.count) editors in pool", component: LogComponents.editorPool)
            editor.prepareForReuse()
            editor.increaseUseCount()
            editor.isHidden = false
            editor.poolIndex = itemRecorder.count - items.count - 1
            return editor
        } else {
            let editor = createWebEditor()
            DocsLogger.info("get new editor \(editor.editorIdentity)", component: LogComponents.editorPool)
            DocsLogger.info("createWebEditor current total:\(itemRecorder.count), \(items.count) editors in pool", component: LogComponents.editorPool)
            editor.preload()
            editor.increaseUseCount()
            spaceAssert(!editor.isHidden)
            return editor
        }
    }

    public func reclaim(editor: ResuableItem) {
        DocsLogger.info("editor is reclaimed, editor: \(editor.editorIdentity)", component: LogComponents.editorPool)
        DocsLogger.info("====reclaim WebView's count \(self.itemRecorder.count) / EditorsPool's count \(self.items.count) ====", component: LogComponents.editorPool)
        var needAbandoned = false
        if let browserView = editor as? WebBrowserView {
            needAbandoned = browserView.notReloadMainFrameOfFullPkg
        } else {
            DocsLogger.error("Editor must be BrowserView", component: LogComponents.editorPool)
            spaceAssertionFailure("为了确保精简包切换为完整包时的逻辑，需要Editor为BrowserView")
        }
        // 移除上个租户未被清除webView
        // iPad场景下切换租户的时候有文档被打开了，这个时候它在使用，不在复用池中，VC dismiss的时机比登出清除的时机慢，导致这个webView被重新加入复用池中(黑户)
        let curUserId = self.userResolver.userID
        guard let attachUserId = editor.attachUserId, attachUserId == curUserId else {
            itemRecorder.remove(editor)
            tryFillEditorPool(delay: 0)
            DocsLogger.info("reclaim old editor", extraInfo: ["editor": editor.reuseState], error: nil, component: LogComponents.editorPool)
            return
        }
        guard editor.hasPreloadSomething == true, editor.usedCounter < maxUsedCountPerItem,
            !needAbandoned else {
            NotificationCenter.default.post(name: Notification.Name.Docs.preloadDocsStart,
                                            object: nil,
                                            userInfo: nil )
            if editor.webViewClearDone.value {
                itemRecorder.remove(editor)
                tryFillEditorPool(delay: 0)
            } else {
                self.addObserverWebviewClearDone(editor)
            }
            DocsLogger.info("editor reclaim failed", extraInfo: ["editor": editor.reuseState], error: nil, component: LogComponents.editorPool)
            return
        }
        if items.contains(editor) {
            DocsLogger.info("editor is already in pool", component: LogComponents.editorPool)
            return
        }
        let usableItems = items.filter { $0.hasPreloadSomething == true && $0.usedCounter < maxUsedCountPerItem }
        if usableItems.count <= getCurrentMaxCount() * 2, self.canBackToEditorPool() {
            DocsLogger.info("editor reclaim success", extraInfo: ["editor": editor.reuseState], error: nil, component: LogComponents.editorPool)
            addEditorToPool(editor)
        } else {
            DocsLogger.info("editor reclaim failed", extraInfo: ["editor": editor.reuseState], error: nil, component: LogComponents.editorPool)
        }

        if !editor.isInEditorPool {
            DocsLogger.info("editor reclaim failed last", extraInfo: ["editor": editor.reuseState], error: nil, component: LogComponents.editorPool)
            if editor.webViewClearDone.value {
                itemRecorder.remove(editor)
            } else {
                self.addObserverWebviewClearDone(editor)
            }
        }
        DocsLogger.info("reclaim current total:\(itemRecorder.count), \(items.count) editors in pool", component: LogComponents.editorPool)
    }

    private func canBackToEditorPool() -> Bool{
        guard EditorsPool.docxDynamicWebViewCountEnable(), isInVCFollow == false else {
            return true
        }
        // 复用池是空的，可以放回去
        if self.items.isEmpty {
            return true
        }
        let removePoolWebViewFirst = SettingConfig.docsWebViewConfig?.removePoolWebViewFirst ?? false
        if removePoolWebViewFirst {
            //因为文档退出时还在做一些更新，为了优先回收正在的webview
            //先移除复用池里还没有加载好的webview， 再移除复用池里的其它webview
            let sortItems = items.sorted { $0.hasPreloadSomething && !$1.hasPreloadSomething }
            if let removeItem = items.last {
                let dropReason: DropReason = removeItem.hasPreloadSomething ? .tooMany : .notPreloadReay
                dropEditor(removeItem, for: dropReason)
            }
            DocsLogger.info("canBackToEditorPool: true, remove Pool WebView First", component: LogComponents.editorPool)
            return true
        } else {
            // 如果复用池里的webview还没有加载好，移除掉复用池里的
            let unreadyItems = items.filter{ $0.hasPreloadSomething == false }
            if unreadyItems.isEmpty == false {
                dropEditor(unreadyItems[0], for: .notPreloadReay)
                return true
            }
            // 复用池里已经有一个加载好模版的，不用再放回去
            DocsLogger.info("canBackToEditorPool: false, use Pool WebView First", component: LogComponents.editorPool)
            return false
        }
    }
    
    public func preload() {
        tryFillEditorPool(delay: 0)
    }
    
    public func drain() {
        spaceAssert(Thread.isMainThread, "operate editor pool in non-main thread")
        DispatchQueue.safetyAsyncMain { [weak self] in
            guard let self = self else { return }
            DocsLogger.info("pool drain remove all items", component: LogComponents.editorPool)
            self.items.forEach {
                $0.isInEditorPool = false
                $0.removeFromViewHierarchy(false)
                self.itemRecorder.remove($0)
            }
            self.items.removeAll()
            DocsLogger.info("drain current total:\(self.itemRecorder.count), \(self.items.count) editors in pool", component: LogComponents.editorPool)
        }
    }
    
    private func VCMoreCountEnable() -> Bool {
        if UserScopeNoChangeFG.GXY.msShareOptimizationEnable,
           isInVCFollow,
           SKDisplay.phone,
           (MobileClassify.mobileClassType == .highMobile || MobileClassify.mobileClassType == .middleMobile) {
            return true
        }
        return false
    }
    
    private func webviewReuseEnableInMS() -> Bool {
//        let abKey = "docs_ms_webview_reuse_enable_ios"
//        let abEnable: Bool
//        if let value = Tracker.experimentValue(key: abKey, shouldExposure: true) as? Int, value == 1 {
//            abEnable = true
//        } else {
//            abEnable = false
//        }
        if UserScopeNoChangeFG.CS.msWebviewReuseEnable,
           isInVCFollow,
           SKDisplay.phone {
            return true
        }
        return false
    }

    private func getCurrentMaxCount() -> Int {
        var result: Int
        var debugInfo: String
        if webviewReuseEnableInMS() {
            let hasWebviewInMS = self.itemRecorder.webViewList.contains(where: { $0.isInVCFollow }) //MS中有正在使用的web
            if hasWebviewInMS {
                result = maxCount
                debugInfo = "has_webview_in_ms"
            } else if self.items.isEmpty { //tab打开文档后再在MS中打开文档,要有可复用的web
                result = maxCount + 1
                debugInfo = "items_is_empty"
            } else {
                debugInfo = "web_reuse_in_ms_enable"
            }
        }
        if VCMoreCountEnable() { // VC下单独的开关，其他场景稳定后，下面两个FG可以删掉统一
            result = maxCount + 1
            debugInfo = "vc_more_count"
        } else if EditorsPool.docxDynamicWebViewCountEnable()  {
            result = maxCount + 1
            debugInfo = "docx_dynamic_count"
        }
        result = maxCount
        debugInfo = ""
        DocsLogger.info("getCurrentMaxCount:\(result), debugInfo:\(debugInfo)", component: LogComponents.editorPool)
        return result
    }
    
    private func canFillNewEditorPool() -> Bool{
        guard currentAvaliableMemorySizeIsSatisfyForGeneric() else {
            return false
        }
        guard EditorsPool.docxDynamicWebViewCountEnable(), isInVCFollow == false else {
            return true
        }
        guard self.itemRecorder.count > 0 else {
            return true
        }
        // 当前已经创建了>=1个webview，并且打开的文档已经成功，当前内存可用，才可以加载下一个
        if hasOpenDocs(), docsOpenFinish(vcfollow: false), currentAvaliableMemorySizeIsSatisfyForMoreWebView() {
            return true
        }
        return false
    }

    private func tryFillEditorPool(delay: Double) {
        if OpenAPI.useSingleWebview {
            DocsLogger.info("using single webview, do not fill editor pool", component: LogComponents.editorPool)
            return
        }
        
        if NewBootManager.shared.liteConfigEnable(),
           SettingConfig.docsWebViewConfig?.disableLowMobilePreload ?? false {
            //低端机直接禁用WebView预加载
            DocsLogger.warning("disable Low Mobile Preload webview", component: LogComponents.editorPool)
            return
        } else if DocsUserBehaviorManager.isEnable() {
            if MobileClassify.isLow, !DocsUserBehaviorManager.shared.shouldPreloadWebView() {
                //在低端机对用户行为进行管控，太久没打开文档则取消WebView预加载
                DocsLogger.warning("should not PreloadWebView with UserBehavior, \(LogComponents.UserBehavior)", component: LogComponents.editorPool)
                let interruptParams: [String: Any] = ["interrupt_type": "webview"]
                DocsTracker.log(enumEvent: .performanceDocForecast, parameters: interruptParams)
                return
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let `self` = self else { return }
            let maxCount = self.getCurrentMaxCount()
            guard self.items.count < maxCount else { return }
            guard self.isInForeground, !self.userResolver.isPlaceholder, self.userResolver.valid else { return }
            if self.itemRecorder.count < maxCount {
                DocsLogger.info("tryFillEditorPool prepare new editor", component: LogComponents.editorPool)
                self.prepareEditor()
            }
        }
    }

    private func keepMinimumEditor() {
        let itemsCopy = items
        itemsCopy.dropFirst().forEach { (editor) in
            dropEditor(editor, for: .enterBackground)
        }
        DocsLogger.info("keepMinimum current total:\(itemRecorder.count), \(items.count) editors in pool", component: LogComponents.editorPool)
    }

    private func prepareEditor() {
        guard self.canFillNewEditorPool() else {
            return
        }
        let editor = createWebEditor()
        spaceAssert(editor.preloadStatus.value.hasLoadSomeThing == false)
        editor.openSessionID = nil// 预加载不要算在load里面
        if OpenAPI.delayLoadUrl > 0 {
            //预加载耗时较久，拆分任务到下个runloop处理
            DispatchQueue.main.async {
                editor.addToViewHierarchy().preload()
                self.addEditorToPool(editor)
                self.addPreloadObservesFor(editor)
            }
        } else {
            editor.addToViewHierarchy().preload()
            addEditorToPool(editor)
            addPreloadObservesFor(editor)
        }
        DocsLogger.info("prepareEditor current total:\(itemRecorder.count), \(items.count) editors in pool", component: LogComponents.editorPool)
    }

    private func addPreloadObservesFor(_ editor: ResuableItem) {
        addPreloadTimeoutLogicFor(editor)
        notifyStartPreloadForTest(editor)
    }

    private func addPreloadTimeoutLogicFor(_ editor: ResuableItem) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 120) { [weak self, weak editor] in
            guard let `self` = self, let editor = editor else { return }
            if editor.preloadStatus.value.hasLoadSomeThing == false {
                let status = PreloadStatus()
                PreloadStatistics.shared.endRecordPreload(editor.editorIdentity,
                                                          hasLoadSomeThing: status.hasLoadSomeThing,
                                                          statisticsStage: status.statisticsStage ?? DocsType.unknownDefaultType.name,
                                                          hasComplete: status.hasComplete)
                self.dropEditor(editor, for: .timeout)
                if self.canAutoPreloadWebView() {
                    self.tryFillEditorPool(delay: 0)
                }
            } else {
                self.continuousFailCount = 0
                DocsLogger.info("reset continuous preload FailCount", component: LogComponents.editorPool)
            }
        }
    }


    private func dropEditor(_ editor: ResuableItem, for reason: DropReason) {
        let logDict: [String: String] = ["id": editor.editorIdentity, "reason": reason.rawValue ]
        DocsLogger.info("drop editor for reason(\(reason.rawValue)", extraInfo: logDict, error: nil, component: LogComponents.editorPool)
        self.removeEditorFromPool(editor)
        self.itemRecorder.remove(editor)
        if reason == .terminated || reason == .timeout {
            if !editor.isResponsive {
                continuousFailCount += 1
                DocsLogger.error("continuous preload FailCount:\(continuousFailCount)", component: LogComponents.editorPool)
                recoverEditorIfNeed(editor: editor, failCount: Int(continuousFailCount), inPool: true)
            } else {
                self.continuousFailCount = 0
                DocsLogger.info("reset continuous preload FailCount", component: LogComponents.editorPool)
            }
        }
    }

    private func addEditorToPool(_ editor: ResuableItem) {
        DocsLogger.info("ready to add editor \(editor.editorIdentity)", component: LogComponents.editorPool)
        if itemRecorder.count <= self.getCurrentMaxCount() {
            editor.isInEditorPool = true
            items.append(editor)
            addObserveTerminateFor(editor)
            
            let useCount = editor.usedCounter
            let isReclaim = useCount > 0 //代码是回收而不是新创建的
            if isReclaim, !editor.isInViewHierarchy, SettingConfig.docsWebViewConfig?.attachOnWindowWhenInPool ?? false {
                editor.attachToWindow()
                let attachOnWindowSeconds = SettingConfig.docsWebViewConfig?.attachOnWindowSeconds ?? 0
                DocsLogger.info("temp attach to window, seconds:\(attachOnWindowSeconds)", component: LogComponents.editorPool) //临时加到window上，方便webview渲染完毕
                if attachOnWindowSeconds > 0 {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(attachOnWindowSeconds), execute: { [weak self, weak editor] in
                        guard let `self` = self, let editor = editor,
                              editor.isInEditorPool, editor.isInViewHierarchy,
                              useCount == editor.usedCounter else {
                            DocsLogger.info("cancel dettach from window", component: LogComponents.editorPool)
                            return
                        }
                        DocsLogger.info("dettach from window", component: LogComponents.editorPool)
                        editor.removeFromViewHierarchy(true)
                    })
                }
            }
            DocsLogger.info("add editor \(editor.editorIdentity) succ", component: LogComponents.editorPool)
        }
    }

    private func removeEditorFromPool(_ editor: ResuableItem) {
        guard let index = items.firstIndex(of: editor) else {
            DocsLogger.info("remove editor \(editor.editorIdentity) fail", component: LogComponents.editorPool)
            return
        }
        editor.isInEditorPool = false
        editor.webViewClearDone.value = false
        items.remove(at: index)
        editor.webviewHasBeenTerminated.bind(target: self, block: nil)
        editor.webViewClearDone.bind(target: self, block: nil)
        editor.removeFromViewHierarchy(false)
        DocsLogger.info("remove editor \(editor.editorIdentity) succ", component: LogComponents.editorPool)
    }

    private func addObserveTerminateFor(_ editor: ResuableItem) {
        editor.webviewHasBeenTerminated.bind(target: self) { [weak self, weak editor] (terminated) in
            guard terminated, let self = self, let editor = editor else { return }
            DocsLogger.info("handle webviewHasBeenTerminated \(editor.editorIdentity)  ", component: LogComponents.editorPool)
            self.dropEditor(editor, for: .terminated)
            // 没有文档打开，同时复用池是空，再做填充
            if self.items.isEmpty, self.hasOpenDocs() == false, self.canAutoPreloadWebView() {
                self.tryFillEditorPool(delay: 0)
            }
            DocsLogger.info("====ObserveTerminateFor WebView's count \(self.itemRecorder.count) / EditorsPool's count \(self.items.count) ====")
        }
    }
    
    private func addObserverWebviewClearDone(_ editor: ResuableItem) {
        editor.webViewClearDone.bind(target: self) { [weak self, weak editor] (hasClearDone) in
            guard hasClearDone, let self = self, let editor = editor else { return }
            self.removeEditorFromRecorder(editor)
        }
        // 增加兜底逻辑，最长时间等2s，将webview移除
        let delay = SettingConfig.docsWebViewConfig?.aliveAfterClearSeconds ?? 2
        DocsLogger.info("delay remove webview after \(delay) seconds", component: LogComponents.editorPool)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(delay), execute: { [weak self, weak editor] in
            guard let `self` = self, let editor = editor else { return }
            DocsLogger.info("clearDone's timeout", component: LogComponents.editorPool)
            self.removeEditorFromRecorder(editor)
        })
    }
    
    private func removeEditorFromRecorder(_ editor: ResuableItem) {
        DocsLogger.info("handle webviewClearDone \(editor.editorIdentity)  ", component: LogComponents.editorPool)
        if self.itemRecorder.contains(editor) {
            self.itemRecorder.remove(editor)
            editor.webViewClearDone.bind(target: self, block: nil)
            editor.webViewClearDone.value = false
            self.tryFillEditorPool(delay: 0)
            DocsLogger.info("====ObserveWebviewClearDone WebView's count \(self.itemRecorder.count) / EditorsPool's count \(self.items.count) ====")
        }
    }

    private func getReuseableEditorFor(type: DocsType) -> ResuableItem? {
        guard !OpenAPI.docs.disableEditorResue else { return nil }
        var resuableEditor: ResuableItem?
        if let editor = items.first(where: { $0.canReuse(for: type) }) {
            resuableEditor = editor //优先缓存预加载了对应文档类型的WebView
        } else if let editor = items.first(where: { $0.hasPreloadSomething }) {
            resuableEditor = editor //缓存了任意文档类型的也行
        } else if let editor = items.first(where: { !$0.webviewHasBeenTerminated.value }) {
            resuableEditor = editor
        }
        if let editor = resuableEditor {
            DocsLogger.info("\(editor.editorIdentity) editor is reused: YES", component: LogComponents.editorPool)
            return editor
        } else {
            DocsLogger.info("editor is reused: NO", component: LogComponents.editorPool)
            return nil
        }
    }

    private func createWebEditor() -> ResuableItem {
        let currentTime = Date().timeIntervalSince1970
        let editor = editorCreation(.webEditor)
        editor.preloadStartTimeStamp = currentTime
        editor.attachUserId = self.userResolver.userID
        editor.webViewClearDone = ObserableWrapper<Bool>(false)
        itemRecorder.add(editor)
        return editor
    }
    
    public func getAllItems() -> [ResuableItem] {
        return self.itemRecorder.webViewList
    }
    
    /// 内存大小是否满足加载更多webview
    private func currentAvaliableMemorySizeIsSatisfyForMoreWebView() -> Bool {
        let memoryInfo = MemoryUtil.reportMemory()
        let maxMemory = Float(memoryInfo.totalMb)
        let usedMb = memoryInfo.usedMb
        guard memoryInfo.success else {
            DocsLogger.info("get current memorysize fail", component: LogComponents.editorPool)
            return false
        }
        DocsLogger.info("limitMemorySize:\(self.limitMemorySize), maxMemory:\(maxMemory), usedMb:\(usedMb)", component: LogComponents.editorPool)
        // 剩余内存=设备OOM内存值-当前app占用内存 > 100M满足,webview大概占用200M
        if EditorsPool.docxDynamicWebViewCountEnable(), self.limitMemorySize > 0 {
            let leftMemory = self.limitMemorySize
            if leftMemory > (usedMb + UInt64(OpenAPI.docs.preloadWebViewMemorySize)) {
                return true
            }
            return false
        } else {
            let ratio = OpenAPI.docs.msMemoryRatio
            let maxAvaliableMemory = Int64(maxMemory * ratio)
            if maxAvaliableMemory > usedMb {
                return true
            }
            return false
        }
    }
    
    /// 内存大小是否满足加载webview
    private func currentAvaliableMemorySizeIsSatisfyForGeneric() -> Bool {
        let memoryInfo = MemoryUtil.reportMemory()
        let leftMemory = memoryInfo.totalMb - memoryInfo.usedMb
        let oomMemory = self.limitMemorySize
        var isSatisfy = true //和旧逻辑一致，默认可以
        
        defer {
            DocsLogger.info("check memory SatisfyForGeneric(\(isSatisfy), usedMem:\(memoryInfo.usedMb), remain:\(leftMemory),oomMem:\(oomMemory)", component: LogComponents.editorPool)
        }
        
        guard let minRemainPreloadWebViewMemorySize = SettingConfig.docsPreloadTimeOut?.minRemainPreloadWebViewMemorySize, minRemainPreloadWebViewMemorySize > 0 else {
            return true // 没有配置则保持旧逻辑，不控制
        }
        if leftMemory > minRemainPreloadWebViewMemorySize {
            return true // 条件1：可用内存足够，可预加载
        }
        
        guard oomMemory > 0 else {
            return true // 没有配置则保持旧逻辑，不控制
        }
        if oomMemory > (memoryInfo.usedMb + UInt64(OpenAPI.docs.preloadWebViewMemorySize)) {
            return true // 条件2：距离OOM内存足够，可预加载
        }
        
        isSatisfy = false
        return false
    }
    
    @objc
    private func didChangeModule(_ notification: Notification) {
        guard UserScopeNoChangeFG.GXY.msShareOptimizationEnable else {
            return
        }
        isInVCFollow = (HostAppBridge.shared.call(GetVCRuningStatusService()) as? Bool) ?? false
        guard isInVCFollow, canPreloadInVC() else { return }
            // 1.如果当前复用池里有，不预加载
            // 2.判断当前是否有正在打开的文档，不抢占当前文档的资源
        if items.isEmpty, docsOpenFinish(vcfollow: true) {
            DocsLogger.info("VC preload", component: LogComponents.editorPool)
            self.preload()
        } else {
            DocsLogger.info("docs open not finish or no need wait to preload", component: LogComponents.editorPool)
        }
    }
    
    @objc
    private func didReceiverOpenDocsEnd(info: NSNotification) {
        guard let infoData =  info.object as? [String: Bool], infoData["open_docs_result"] ?? false else {
            DocsLogger.info("recived docsOpen finish but not success", component: LogComponents.editorPool)
            return
        }
        DocsLogger.info("recived docsOpen finish", component: LogComponents.editorPool)
        isInVCFollow = (HostAppBridge.shared.call(GetVCRuningStatusService()) as? Bool) ?? false
        // VC下
        if UserScopeNoChangeFG.GXY.msShareOptimizationEnable,
           isInVCFollow {
            guard canPreloadInVC() else { return }
            self.preload()
        } else if EditorsPool.docxDynamicWebViewCountEnable() {
            guard currentAvaliableMemorySizeIsSatisfyForMoreWebView() else {
                DocsLogger.info("common preload fail, notlowMobile:\(MobileClassify.mobileClassType), FG:\(UserScopeNoChangeFG.GXY.docxDynamicWebViewCountEnable)", component: LogComponents.editorPool)
                return
            }
            self.preload()
        }
    }
    
    ///用之前需要判断当前是否处于VC状态
    private func canPreloadInVC() -> Bool {
        if SKDisplay.phone, (MobileClassify.isHigh || MobileClassify.isMiddle), currentAvaliableMemorySizeIsSatisfyForMoreWebView() {
            return true
        } else {
            DocsLogger.info("VC preload fail, notlowMobile:\(MobileClassify.mobileClassType),VC:\(isInVCFollow), FG:\(UserScopeNoChangeFG.GXY.msShareOptimizationEnable)", component: LogComponents.editorPool)
            return false
        }
    }

    // 当前打开文档都已经加载成功
    private func docsOpenFinish(vcfollow: Bool) -> Bool {
        return itemRecorder.docsOpenFinish(vcfollow: vcfollow)
    }
    
    private func hasOpenDocs() -> Bool {
        return itemRecorder.hasOpenDocs()
    }

    func notifyStartPreloadForTest(_ editor: ResuableItem) {
        guard DocsSDK.isBeingTest else { return }
        NotificationCenter.default.post(name: Notification.Name.PreloadTest.preloadStart,
                                        object: nil,
                                        userInfo: [Notification.DocsKey.editorIdentifer: editor.editorIdentity])
    }

}

extension ProcessInfo {
    //只计算一次
    static let isWebviewCrashOnTerminate: Bool = {
        let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let leastCrashSystemVersion = OperatingSystemVersion(majorVersion: 11, minorVersion: 3, patchVersion: 0)
        if ProcessInfo.processInfo.isOperatingSystemAtLeast(leastCrashSystemVersion) && operatingSystemVersion.majorVersion < 12 {
            DocsLogger.info("WebviewCrashOnTerminate", component: LogComponents.editorPool)
            return true
        } else if operatingSystemVersion.majorVersion == 12 {
            let needDelay = OpenAPI.needDelayDeallocWebview
            DocsLogger.info("WebviewCrashOnTerminate ?? \(needDelay)", component: LogComponents.editorPool)
            return needDelay
        } else {
            DocsLogger.info("Webview not CrashOnTerminate", component: LogComponents.editorPool)
            return false
        }
    }()
}

extension BrowserView {
    public func loadFailView() {}
}
