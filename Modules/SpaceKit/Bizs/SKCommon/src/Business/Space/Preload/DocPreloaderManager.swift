//
//  DocPreloader.swift
//  SpaceKit
//
//  Created by weidong fu on 2019/1/22.
//  swiftlint:disable file_length
//  swiftlint:disable type_body_length

import Foundation
import SKFoundation
import SwiftyJSON
import SKResource
import TTNetworkManager
import SKUIKit
import LKCommonsTracker
import RunloopTools
import SpaceInterface
import LarkPreload
import SKInfra
import RxRelay
import LarkContainer

public extension CCMExtension where Base == UserResolver {

    var docPreloaderManagerAPI: DocPreloaderManagerAPI? {
        if CCMUserScope.docEnabled {
            let obj = try? base.resolve(type: DocPreloaderManagerAPI.self)
            return obj
        } else {
            return DocPreloaderManager.singleInstance as? DocPreloaderManagerAPI
        }
    }
}

extension DocsType {
    public var shouldPreloadClientVar: Bool {
        let validTypes: Set<DocsType> = [.bitable, .sheet, .doc, .file, .mindnote, .wiki, .docX]
        return validTypes.contains(self)
    }
}

extension FromSource {
    var toDrivePreloadType: DrivePreloadSource? {
        switch self {
        case .quickAccess: return .pin
        case .recent, .recentPreload: return .recent
        case .favorites: return .favorite
        default:
            return nil
        }
    }
}

struct RequestPermissionResult {
    var hasRequestPermission: Bool = false //是否发送过权限请求
    var hasPermission: Bool = false //权限请求结果
    
    mutating func updateHasRequestPermission(hasRequestPermission: Bool) {
        self.hasRequestPermission = hasRequestPermission
    }
}

struct SubBlockPreloadState {
    var votePreload: Bool = false //投票预加载结果
    var commentPreload: Bool = false //评论预加载结果
    var htmlPreload: Bool = false //html预加载结果，用于doc
    var htmlNativePreload: Bool = false //html本地预加载结果，用于docx
    var htmlNativeRequestCount: Int = 0 // SSR预加载请求次数，生命周期内不超过3次
}

public final class DocPreloaderManager {
    fileprivate static let singleInstance = DocPreloaderManager(userResolver: nil) //TODO.chensi 用户态迁移完成后删除旧的单例代码
    static public let preloadNotificationKey = "docs_preload_keys"
    private let preloadClientVarAbility: DocPreloadClientVarAbility
    private let notificationCenter: NotificationCenter
    private weak var resolver: DocsResolver?
    lazy private var newCache: NewCacheAPI? = resolver?.resolve(NewCacheAPI.self)
    let userResolver: UserResolver? // nil表示单例
    
    // Docx-SSR预加载队列，高优队列
    private let htmlNativePreloaderQueue: SequeuePreloader<NativePerloadHtmlTask> = {
        if DocPreloaderManager.enableQueuePriority() {
            return SequeuePreloader<NativePerloadHtmlTask>(logPrefix: "htmlNativePreload", preloadQueue: DispatchQueue(label: "com.docs.preloadQueue-SRR"))
        } else {
            return SequeuePreloader<NativePerloadHtmlTask>(logPrefix: "htmlNativePreload", preloadQueue: defaultPreloadQueue)
        }
    }()
    
    // ClientVars预加载队列，高优队列
    static let clientvarPreloadQueue = DispatchQueue(label: "com.docs.preloadQueue-clientvar")
    private let clientVarPreloaderQueue = SequeuePreloader<PreloadClientVarTask>(logPrefix: "clientVarPre", preloadQueue: DocPreloaderManager.enableQueuePriority() ? clientvarPreloadQueue : defaultPreloadQueue)
    private let clientVarPreloaderQueueForLark = SequeuePreloader<PreloadClientVarTask>(logPrefix: "clientVarLarkPre", preloadQueue: DocPreloaderManager.enableQueuePriority() ? clientvarPreloadQueue : defaultPreloadQueue)
    private let clientVarPreloaderQueueForManuOffline = SequeuePreloader<PreloadClientVarTask>(logPrefix: "manuPreload", preloadQueue: DocPreloaderManager.enableQueuePriority() ? clientvarPreloadQueue : defaultPreloadQueue)
    
    // 其他任务的队列，低优队列
    static let defaultPreloadQueue: DispatchQueue = {
        if DocPreloaderManager.enableQueuePriority() {
            return DispatchQueue(label: "com.docs.preloadQueue-default", qos: DispatchQoS.utility)
        } else {
            return DispatchQueue(label: "com.docs.preloadQueue-default")
        }
    }()
    private let htmlPreloaderQueue = SequeuePreloader<PreloadHtmlTask>(logPrefix: "htmlPreload", preloadQueue: defaultPreloadQueue)
    private let wikiHtmlNativePreloaderQueue = SequeuePreloader<NativePerloadHtmlTask>(logPrefix: "wikiHtmlNativePreload", preloadQueue: defaultPreloadQueue)
    private let picturePreloaderQueue = SequeuePreloader<PreloadPictureTask>(logPrefix: "picturePreload", preloadQueue: defaultPreloadQueue, preloaderType: .single)
    private let votePreloaderQueue = SequeuePreloader<RNPreloadTask>(logPrefix: "votePreload ", preloadQueue: defaultPreloadQueue, preloaderType: .single)
    private let commentPreloaderQueue = SequeuePreloader<RNPreloadTask>(logPrefix: "commentPreload ", preloadQueue: defaultPreloadQueue, preloaderType: .single)
    
    // 持久化队列
    private let saveTaskToFileQueue = DispatchQueue(label: "com.docs.saveTaskToFile", target: defaultPreloadQueue)
    
    @ThreadSafe private var saveToFileTasksKeys: [PreloadKey] = Array()
    //缓存权限请求，避免多次请求
    private let permissionUpdateQueue = DispatchQueue(label: "com.docs.permissionPreload")
    private var requestPermissionCacahe = ThreadSafeDictionary<String, RequestPermissionResult>()
    private var requestPermissionRecord = ThreadSafeDictionary<String, PreloadDataRecord>()
    private lazy var needUpdatePermissionCache: ThreadSafeSet<String> = { ThreadSafeSet<String>() }()
    private lazy var throttle: SKThrottle = { SKThrottle(interval: 1.0) }()
    //存放subblock预加载结果
    private var preloadState = ThreadSafeDictionary<String, SubBlockPreloadState>()
    // 存放RNLoadSuccess前的预加载key
    @ThreadSafe private var waitRNTasksKeys: [PreloadKey] = Array()
    @ThreadSafe private var weakNetTasksKeys: [PreloadKey] = Array()
    let docRNPreloader: DocRNPreloader
    let clientVarPreloaderType: ClientVarPreloader.Type
    private var userPermissionRequest: DocsRequest<JSON>?
    static var delegate: BrowserJSEngine?
    private var isReadyJS = ObserableWrapper<Bool>(false)
    @ThreadSafe private var preloadHtmlArray: [PreloadHtmlTask]?
    private var userDidCleanCache: Bool = false
    private var idleSSRDataPrepared: Bool = false   // SSR闲时预加载，生命周期内做一次
    private var idleSSRDataArray: [PreloadKey]?
    // Docx文档预加载任务入队时间，统计用
    private var preloadSSREnqueueTimeCacahe = ThreadSafeDictionary<String, TimeInterval>()
    private var preloadClientVarsEnqueueTimeCacahe = ThreadSafeDictionary<String, TimeInterval>()

    /// 预加载图片出现403的文档，标记为不再预加载图片
    private lazy var specialFileToken: [String] = {
        let uid = User.current.info?.userID ?? ""
        let values: Data? = CacheService.configCache.object(forKey: "ccm.bytedance.preload" + uid)
        guard let resultValue = values else { return [] }
        var tokens: [String] = []
        do {
            tokens = try JSONDecoder().decode([String].self, from: resultValue)
        } catch {
            spaceAssertionFailure("preload token cache get error")
        }
        return tokens
    }()

    private let preloadQueue: DispatchQueue = {
        if DocPreloaderManager.enableQueuePriority() {
            return DispatchQueue(label: "com.docs.preloadQueue")
        } else {
            return DispatchQueue(label: "com.docs.preloadQueue", target: defaultPreloadQueue)
        }
    }()
        
    init(userResolver: UserResolver?,
         clientVarPreloaderType: ClientVarPreloader.Type = DocsRequest<Any>.self,
         preloadClientVarAbility: DocPreloadClientVarAbility = User.current,
         notificationCenter: NotificationCenter = .default, resolver: DocsResolver = DocsContainer.shared) {
        self.userResolver = userResolver
        self.resolver = resolver
        self.docRNPreloader = DocRNPreloader(preloadQueue: Self.enableQueuePriority() ? Self.clientvarPreloadQueue : Self.defaultPreloadQueue,
                                             userResolver: userResolver)//通过RN获取数据
        self.clientVarPreloaderType = clientVarPreloaderType
        self.preloadClientVarAbility = preloadClientVarAbility
        self.notificationCenter = notificationCenter
        notificationCenter.addObserver(self,
                                       selector: #selector(didReceivePreloadNotification(_:)),
                                       name: Notification.Name.Docs.addToPreloadQueue,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(didReceiveWillLogoutNotification(_:)),
                                       name: Notification.Name.Docs.userWillLogout,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(finishLoadJS(_:)),
                                       name: Notification.Name.Docs.preloadDocsFinished,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(startLoadJS(_:)),
                                       name: Notification.Name.Docs.preloadDocsStart,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(userWillCleanCache(_:)),
                                       name: Notification.Name.Docs.userWillCleanNewCache,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(didReceiveRNLoadCompleteNotification(_:)),
                                       name: Notification.Name.Docs.rnSetupEnviromentComplete,
                                       object: nil)

        DocsNetStateMonitor.shared.addObserver(picturePreloaderQueue) { [weak self] (netType, _) in
            guard let self = self else { return }
            self.picturePreloaderQueue.netStatus = netType
            self.clientVarPreloaderQueue.netStatus = netType
            self.htmlPreloaderQueue.netStatus = netType
            self.htmlNativePreloaderQueue.netStatus = netType
            self.wikiHtmlNativePreloaderQueue.netStatus = netType
            self.clientVarPreloaderQueueForLark.netStatus = netType
            self.commentPreloaderQueue.netStatus = netType
            self.votePreloaderQueue.netStatus = netType
            self.clientVarPreloaderQueueForManuOffline.netStatus = netType
        }
        self.addCompleteBlockToQueue()
        self.setupNetworkMonitor()
        self.readPermissionFromFile()
        self.registerIdleSSRPreloadtask()
        self.checkRecoverArchedTask()
    }
    
    static func enableQueuePriority() -> Bool {
        guard UserScopeNoChangeFG.GXY.docsPreloadQueuePriorityEnable else {
            return false
        }
        
#if DEBUG
        return true
#else
        if let abEnable = Tracker.experimentValue(key: "docs_preload_queue_priority_enable", shouldExposure: true) as? Int, abEnable == 1 {
            return true
        }
        return false
#endif
    }
    
    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { (networkType, isReachable) in
            DocsLogger.info("Current networkType info, networkType: \(networkType), isReachable: \(isReachable)", component: LogComponents.preload)
            guard isReachable else { return }
            DispatchQueue.main.async { // 监听网络变化的对象比较多，避免在同一个runloop执行操作卡顿
                if !self.weakNetTasksKeys.isEmpty {
                    let tmpSequcece = self.weakNetTasksKeys
                    self.weakNetTasksKeys.removeAll()
                    self.add(tmpSequcece, to: self.clientVarPreloaderQueueForLark)
                }
            }
        }
    }

    @objc
    private func userWillCleanCache(_ notification: Notification) {
        preloadQueue.async { [weak self] in
            guard let self = self else { return }
            DocsLogger.info("userWillCleanCache, remove all preload tasks", component: LogComponents.preload)
            self.clearAllQueue()
            self.userDidCleanCache = true
        }
    }
    
    @objc
    private func startLoadJS(_ notification: Notification) {
        DocsLogger.info("preload html startLoadJS", component: LogComponents.preload)
        isReadyJS.value = false
        self.isReadyJS.bind(target: self) { [unowned self] (status) in
            guard status == true else { return }
            DocsLogger.info("preload html js become ready", component: LogComponents.preload)
            
            guard self.preloadHtmlArray != nil else { return }
            self.htmlPreloaderQueue.addTasks(self.preloadHtmlArray!)
            self.preloadHtmlArray = nil
        }
    }
    @objc
    private func finishLoadJS(_ notification: Notification) {
        DocsLogger.info("preload html finishLoadJS", component: LogComponents.preload)
        if !(DocsContainer.shared.resolve(SKBrowserInterface.self)?.browsersStackIsEmptyObsevable ?? BehaviorRelay<Bool>(value: true)).value {
            isReadyJS.value = true
        }
    }
    
    @objc
    private func didReceiveWillLogoutNotification(_ notification: Notification) {
        clearAllQueue()
    }
    
    @objc
    private func didReceiveRNLoadCompleteNotification(_ notification: Notification) {
        DocsLogger.info("didReceiveRNLoadCompleteNotification", component: LogComponents.preload)
        if !self.waitRNTasksKeys.isEmpty {
            let tmpSequcece = self.waitRNTasksKeys
            self.waitRNTasksKeys.removeAll()
            self.add(tmpSequcece, to: self.clientVarPreloaderQueueForLark)
        }
    }

    private func clearAllQueue() {
        self.picturePreloaderQueue.clear()
        self.clientVarPreloaderQueue.clear()
        self.commentPreloaderQueue.clear()
        self.votePreloaderQueue.clear()
        self.htmlPreloaderQueue.clear()
        self.wikiHtmlNativePreloaderQueue.clear()
        self.clientVarPreloaderQueueForLark.clear()
        self.preloadHtmlArray?.removeAll()
        self.requestPermissionCacahe.removeAll()
        self.requestPermissionRecord.removeAll()
        self.needUpdatePermissionCache.removeAll()
        self.preloadState.removeAll()
        self.saveToFileTasksKeys.removeAll()
        self.waitRNTasksKeys.removeAll()
        self.weakNetTasksKeys.removeAll()
        self.preloadSSREnqueueTimeCacahe.removeAll()
        self.preloadClientVarsEnqueueTimeCacahe.removeAll()
    }

    /// 手动离线预加载任务
    /// - Parameter preloadKeys: 需要被预加载的keys
    public func addManuOfflinePreloadKey(_ preloadKeys: [PreloadKey]) {
        DispatchQueue.global().async {
            guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
                return
            }
            var tokenInfos = [FileListDefine.ObjToken: SyncStatus]()
            preloadKeys.forEach { (key) in
                if key.type == .file {
                    DocsLogger.info("addManuOfflinePreloadKey, count=\(preloadKeys.count), key.type=file", component: LogComponents.preload)
                    return
                }
                var objToken = key.objToken
                if let wikiInfo = key.wikiInfo {
                    // 列表中的Wiki文档Objtoken是WikiToken, 用真正的objToken去DB中取数据取不到，手动替换一下
                    objToken = wikiInfo.wikiToken
                }
                guard let fileEntry = dataCenterAPI.spaceEntry(objToken: objToken) else {
                    DocsLogger.info("addManuOfflinePreloadKey, count=\(preloadKeys.count), fileEntry=nil", component: LogComponents.preload)
                    return
                }
                if key.hasClientVar {
                    _ = fileEntry.syncStatus.downloadStatus
                    if !fileEntry.syncStatus.downloadStatus.hasSuccess {
                        tokenInfos[objToken] = fileEntry.syncStatus.modifingDownLoadStatus(.successOver2s)
                    }
                } else {
                    if fileEntry.syncStatus.downloadStatus == .none {
                        self.userDidCleanCache = false
                        tokenInfos[objToken] = fileEntry.syncStatus.modifingDownLoadStatus(.waiting)
                    }
                }
            }
            self.add(preloadKeys, to: self.clientVarPreloaderQueueForManuOffline, isManuOffline: true)
            DocsLogger.info("addManuOfflinePreloadKey, count=\(preloadKeys.count)", component: LogComponents.preload)
            if !tokenInfos.isEmpty {
                dataCenterAPI.updateUIModifier(tokenInfos: tokenInfos)
            }
        }
    }

    /// space列表通过抛通知的方式预加载
    @objc
    private func didReceivePreloadNotification(_ notification: Notification) {
        guard let info = notification.userInfo,
            let preloadKeys = info[DocPreloaderManager.preloadNotificationKey] as? [PreloadKey] else { return }
        preloadQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.userDidCleanCache == false else {
                DocsLogger.info("user manual clean cache,  not preload，didReceivePreloadNotification,count=\(preloadKeys.count)", component: LogComponents.preload)
                return
            }
            guard !preloadKeys.isEmpty, self.preloadClientVarAbility.canLoad else {
                DocsLogger.info("user info is \(String(describing: User.current.info)), return", component: LogComponents.preload)
                return
            }

            self.tryPreloadDrive(preloadKeys)

            var maxPreloadCount = SettingConfig.disablePreloadConfig?.maxCount ?? preloadKeys.count
            if let abConfig = Tracker.experimentValue(key: "ccm_preload_source_disabled", shouldExposure: true) as? [String: Any] {
                maxPreloadCount = abConfig["max_space_list_count"] as? Int ?? maxPreloadCount
            }
            let keysToAdd = Array(
                preloadKeys.filter { (preloadKey) -> Bool in
                    if preloadKey.type == .file || preloadKey.wikiInfo?.docsType == .file {
                        return false
                    }
                    return true
                }.prefix(maxPreloadCount)
            )
            DocsLogger.info("didReceivePreloadNotification, count=\(keysToAdd.count)", component: LogComponents.preload)
            self.add(keysToAdd, to: self.clientVarPreloaderQueue)
        }
    }
    
    public func getSSRPreloadTime(_ token: String) -> TimeInterval? {
        return preloadSSREnqueueTimeCacahe.value(ofKey: token)
    }
    
    public func getClientVarsPreloadTime(_ token: String) -> TimeInterval? {
        return preloadClientVarsEnqueueTimeCacahe.value(ofKey: token)
    }
    
    /// IM卡片、Docs_feed等调用DocSDK预加载接口
    public func loadContent(_ url: String, from source: String) {
        func _preload(by key: PreloadKey) {
            DocsLogger.info("loadContent preload start", component: LogComponents.preload)
            self.add([key], to: self.clientVarPreloaderQueueForLark)
        }
        guard let u = URL(string: url), URLValidator.isDocsURL(u) else {
            DocsLogger.warning("invalid doc url", component: LogComponents.preload)
            return
        }
        guard let fileToken = DocsUrlUtil.getFileToken(from: u) else {
            DocsLogger.warning("Can not get file token for doc file", component: LogComponents.preload)
            return
        }
        guard let fileType = DocsUrlUtil.getFileType(from: u) else {
            DocsLogger.warning("Can not get file type for doc file", component: LogComponents.preload)
            return
        }
        guard fileType.shouldPreloadClientVar, fileType != .file else {
            DocsLogger.warning("not supported preload type: \(fileType.name)", component: LogComponents.preload)
            return
        }
        let sourceFrom = PreloadFromSource(rawValue: source)
        // 如果是wiki，先请求到wikiInfo，再进行对应业务预加载
        if fileType == .wiki {
            DocsLogger.info("wiki preload by fileType: \(fileType.name)", component: LogComponents.preload)
            self.resolver?.resolve(SKCommonDependency.self)!
                .setWikiMeta(wikiToken: fileToken) { (wikiInfo, error) in
                    guard let wikiInfo = wikiInfo else {
                        DocsLogger.warning("wiki preload by url failed: \(String(describing: error))", component: LogComponents.preload)
                        return
                    }
                    guard wikiInfo.docsType.shouldPreloadClientVar, wikiInfo.docsType != .file else {
                        DocsLogger.warning("\(wikiInfo.docsType.name) not support preload clientVar", component: LogComponents.preload)
                        return
                    }
                    var preloadKey: PreloadKey
                    if wikiInfo.spaceId.isEmpty {
                        // spaceId 为空表明文档已经不在 wiki 了，后续预加载改为预加载文档本体
                        preloadKey = PreloadKey(objToken: wikiInfo.objToken, type: wikiInfo.docsType)
                    } else {
                        preloadKey = PreloadKey(objToken: fileToken, type: fileType, wikiInfo: wikiInfo)
                    }
                    preloadKey.fromSource = sourceFrom
                    preloadKey.loadPriority = self.preloadPriority(type: fileType, from: sourceFrom)
                    _preload(by: preloadKey)
                    guard URLValidator.isDocsVersionUrl(u), let version = URLValidator.getVersionNum(u) else {
                        return
                    }
                    self.preloadDocsVersions(token: wikiInfo.objToken, type: preloadKey.type, version: version)
                }
        } else {
            var preloadKey = PreloadKey(objToken: fileToken, type: fileType)
            preloadKey.fromSource = sourceFrom
            preloadKey.loadPriority = preloadPriority(type: fileType, from: sourceFrom)
            _preload(by: preloadKey)
            guard URLValidator.isDocsVersionUrl(u), let version = URLValidator.getVersionNum(u) else {
                return
            }
            self.preloadDocsVersions(token: fileToken, type: fileType, version: version)
        }
    }

    private func filter<S: Sequence>(_ keys: S) -> S where S.Element == PreloadKey {
        func _filter(_ keys: S, with rules: [String: [String]]) -> S? {
            return keys.filter { key in
                if let rules = rules[key.type.name] {
                    return !rules.contains(key.fromSource?.rawValue ?? "")
                } else if let defaultRules = rules["default"] {
                    return !defaultRules.contains(key.fromSource?.rawValue ?? "")
                }
                return true
            } as? S
        }
        var filteredKeys = keys
        if let config = SettingConfig.disablePreloadConfig {
            filteredKeys = _filter(keys, with: config.sourceConfig) ?? filteredKeys
        }
        if let abConfig = Tracker.experimentValue(key: "ccm_preload_source_disabled", shouldExposure: true) as? [String: Any],
           let sourceConfig = abConfig["source_config"] as? [String: [String]] {
            filteredKeys = _filter(keys, with: sourceConfig) ?? filteredKeys
        }
        return filteredKeys
    }

    /// 统一添加预加载任务接口
    private func add<S: Sequence>(_ preloadkeys: S, to queue: SequeuePreloader<PreloadClientVarTask>, isManuOffline: Bool = false) where S.Element == PreloadKey {
        self.preloadQueue.async { [weak self] in
            guard let self = self else { return }
            // 弱网环境不进行预加载
            if self.isWeekNetwork() {
                DocsLogger.warning("network is week, do not preload any task", component: LogComponents.preload)
                preloadkeys.forEach { preloadkey in
                    if preloadkey.objToken.isFakeToken == false {
                        self.weakNetTasksKeys.append(preloadkey)
                    }
                }
                return
            }
            // 如果RN还没有初始化成功，加载RN
            guard RNManager.manager.hadSetupEnviroment.value == true else {
                DocsLogger.info("preloader Failure, RNManager not ready", component: LogComponents.preload)
                preloadkeys.forEach { preloadkey in
                    if preloadkey.objToken.isFakeToken == false {
                        self.waitRNTasksKeys.append(preloadkey)
                    }
                }
                return
            }

            var filteredKeys = preloadkeys

            if UserScopeNoChangeFG.LJW.preloadHitOptimizationEnable {
                filteredKeys = self.filter(preloadkeys)
            }

            let enqueueTime = Date().timeIntervalSince1970
            filteredKeys.forEach { (preloadKey) in
                guard preloadKey.objToken.isFakeToken == false else {
                    return
                }
                func _add(_ preloadKey: PreloadKey, enqueueTime: TimeInterval, waitScheduleTime: TimeInterval) {
                    // SSR加载
                    if self.needLoadSSR(preloadKey) {
                        self.fetchPermission(preloadKey: preloadKey, waitRequestResult: false) { [weak self] hasPermission in
                            guard let self = self else { return }
                            if hasPermission {
                                self.preloadSSRTaskNotDependenceClientVars(preloadKey: preloadKey, enqueueTime: enqueueTime, waitScheduleTime: waitScheduleTime)
                            } else {
                                DocsLogger.info("not preload ssr, has no permission", component: LogComponents.preload)
                            }
                        }
                    } else {
                        DocsLogger.info("not need preload ssr", component: LogComponents.preload)
                    }
                    // ClientVars是否需要预加载
                    if self.needLoadClientVars(preloadKey) {
                        self.pauseSubBlockTasks()
                        // 获取权限后，开始预加载clientVars
                        self.fetchPermission(preloadKey: preloadKey) { [weak self] hasPermission in
                            guard let self = self else { return }
                            DocsLogger.info("fetchPermission finish:\(hasPermission)", component: LogComponents.preload)
                            if hasPermission {
                                var saveKey = preloadKey
                                saveKey.updatePreloadClientVars(true)
                                self.updateSaveToFileTask(saveKey)
                                if preloadKey.type == .docX {
                                    self.preloadClientVarsEnqueueTimeCacahe.updateValue(-1, forKey: preloadKey.objToken)
                                }
                                queue.addTasks([self.constrcutClientVarsTask(preloadKey: preloadKey, taskQueue: queue.executeQueue(), isManuOffline: isManuOffline, enqueueTime: enqueueTime, waitScheduleTime: waitScheduleTime) { [weak self] success in
                                    guard let self = self else { return }
                                    self.removeTaskFromSaveList(key: preloadKey, preloadClientVars: true)
                                    // 成功后再继续走其他subBlock加载，图片、评论和投票等依赖ClientVars数据
                                    if success {
                                        self.preloadSubBlocksTask(preloadKey: preloadKey, enqueueTime: enqueueTime)
                                    } else {
                                        DocsLogger.error("preload clientVars fail: \(preloadKey.encryptedObjToken)", component: LogComponents.preload)
                                    }
                                }])
                            }
                        }
                    } else {
                        DocsLogger.info("not need preload clientVars", component: LogComponents.preload)
                    }
                }
                
                if self.canformNoPermission(preloadKey) == false && (self.needLoadSSR(preloadKey) || self.needLoadClientVars(preloadKey)) {
                    if self.canUsePreloadCentralized() && !isManuOffline {
                        DocsLogger.info("add task to centralized queue", component: LogComponents.preload)
                        PreloadMananger.shared.addTask(preloadName: self.preloadTaskName(preloadKey.fromSource?.rawValue ?? FromSource.other.rawValue), biz: .CCM, preloadType: .DocsType, hasFeedback: true, taskAction: {
                            DocsLogger.info("schedule from centralized queue", component: LogComponents.preload)
                            _add(preloadKey, enqueueTime: enqueueTime, waitScheduleTime: Date().timeIntervalSince1970 - enqueueTime)
                        }, stateCallBack: { state in
                            // 如果命中率低被禁用，当前生命周期都不会被执行了，需要移除，防止阻塞subblock的预加载
                            if state == .disableByHitRate {
                                DocsLogger.info("disableByHitRate, removeDisableTask", component: LogComponents.preload)
                                self.removeDisableTask(preloadKey)
                            }
                        }, lowDeviceEnable: self.lowDeviceCanPreload(), diskCacheId: preloadKey.objToken)
                    } else {
                        _add(preloadKey, enqueueTime: enqueueTime, waitScheduleTime: Date().timeIntervalSince1970 - enqueueTime)
                    }
                } else {
                    DocsLogger.info("no need to preload", component: LogComponents.preload)
                }
            }
        }
    }
    
    private func needLoadSSR(_ preloadKey: PreloadKey) -> Bool {

        if !LKFeatureGating.docxSSREnable && !UserScopeNoChangeFG.HZK.enableIpadSSR {
            return false
        }
        
        var usePreloadKey = preloadKey
        if UserScopeNoChangeFG.GXY.wikiDocxSSRQueueEnable, let wikiKey = preloadKey.wikiRealPreloadKey {
            usePreloadKey = wikiKey
        }
        let fileToken = usePreloadKey.objToken
        if let renderKey = DocsType.docX.htmlCachedKey,
            let prefix = User.current.info?.cacheKeyPrefix,
           newCache?.getH5RecordBy(H5DataRecordKey(objToken: fileToken, key: prefix + renderKey))?.payload != nil {
                return false
        }
        guard usePreloadKey.type == .docX else {
            return false
        }
        return true
    }
    
    private func needLoadClientVars(_ preloadKey: PreloadKey) -> Bool {
        return preloadKey.needPreload()
    }
    
    // 确认没有权限
    private func canformNoPermission(_ preloadKey: PreloadKey) -> Bool {
        let preloadKey = preloadKey.wikiRealPreloadKey ?? preloadKey
        let fileToken = preloadKey.objToken
        if requestPermissionCacahe.value(ofKey: fileToken) == nil {
            return false
        }
        let hasRequest = requestPermissionCacahe.value(ofKey: fileToken)?.hasRequestPermission ?? false
        let hasPermission = requestPermissionCacahe.value(ofKey: fileToken)?.hasPermission ?? false
        if hasRequest {
            return !hasPermission
        }
        return false
    }
    
    private func removeDisableTask(_ preloadKey: PreloadKey) {
        let enqueueTime = Date().timeIntervalSince1970
        if preloadKey.wikiRealPreloadKey == nil {
            let htmlNativePreloadTask = preloadKey.makeNativeHtmlTask(canUseCarrierNetwork: !OpenAPI.RecentCacheConfig.isPreloadClientVarOnlyInWifi, enqueueTime: enqueueTime, waitScheduleTime: 0, preloadQueue: self.htmlNativePreloaderQueue.executeQueue())
            self.htmlNativePreloaderQueue.remove(task: htmlNativePreloadTask)
        }
        self.clientVarPreloaderQueue.remove(task: self.constrcutClientVarsTask(preloadKey: preloadKey, taskQueue: self.clientVarPreloaderQueue.executeQueue(), isManuOffline: false, enqueueTime: enqueueTime, waitScheduleTime: 0) { result in
        })
        self.clientVarPreloaderQueueForLark.remove(task: self.constrcutClientVarsTask(preloadKey: preloadKey, taskQueue: self.clientVarPreloaderQueueForLark.executeQueue(), isManuOffline: false, enqueueTime: enqueueTime, waitScheduleTime: 0) { result in
        })
        self.clientVarPreloaderQueueForManuOffline.remove(task: self.constrcutClientVarsTask(preloadKey: preloadKey, taskQueue: self.clientVarPreloaderQueueForManuOffline.executeQueue(), isManuOffline: false, enqueueTime: enqueueTime, waitScheduleTime: 0) { result in
        })
    }
}

// MARK: - Drive
extension DocPreloaderManager {
    private func tryPreloadDrive(_ preloadKeys: [PreloadKey]) {
        let driveFiles = preloadKeys.filter({ $0.type == .file || $0.wikiInfo?.docsType == .file })
        if let driveSource = driveFiles.first?.fromSource?.source?.toDrivePreloadType {
            //DrivePreloadService.shared.handle(files: driveFiles.map { ($0.objToken, nil, $0.driveFileType ?? .unknown)}, source: driveSource)
            DocsContainer.shared.resolve(DrivePreloadServiceBase.self)?.handle(files: driveFiles.map { file in
                var token = file.objToken
                if let realToken = file.wikiInfo?.objToken {
                    token = realToken
                }
                return (token, nil, file.driveFileType ?? .unknown)
            }, source: driveSource)
        }
    }
}

// MARK: - ClientVars
extension DocPreloaderManager {
    private func constrcutClientVarsTask(preloadKey: PreloadKey, taskQueue: DispatchQueue, isManuOffline: Bool, enqueueTime: TimeInterval, waitScheduleTime: TimeInterval, completionHandler:@escaping (Bool) -> Void) -> PreloadClientVarTask {
        let canUseCarrierNetwork: Bool = {
            if preloadKey.fromSource?.source == .recentPreload {
                return !OpenAPI.RecentCacheConfig.isPreloadClientVarOnlyInWifi
            }
            return true
        }()
        var task = preloadKey.makeClientVarTask(canUseCarrierNetwork: canUseCarrierNetwork, preloadQueue: taskQueue, clientVarPreloaderType: clientVarPreloaderType, maxRetryCount: isManuOffline ? 0 : 3, enqueueTime: enqueueTime, waitScheduleTime: waitScheduleTime)
        task.rnPreloader = self.docRNPreloader
        task.willStartTask = { [weak self] in
            guard let self = self else { return }
            DocsLogger.info("client will preload \(preloadKey)", component: LogComponents.preload)
            if preloadKey.type == .docX {
                self.preloadClientVarsEnqueueTimeCacahe.updateValue(Date().timeIntervalSince1970, forKey: preloadKey.objToken)
            }
        }
        task.finishTask = { [weak self] (succ, code, shouldContinue) in
            guard let self = self else { return }
            guard self.userDidCleanCache == false else {
                DocsLogger.info("task.finishTask user manual clean cache, not preload", component: LogComponents.preload)
                return
            }
            if isManuOffline {
                var isSucc: DownloadStatus = succ ? .success : .fail
                if code == DocsNetworkError.Code.coldDocument.rawValue {
                    isSucc = .fail
                }
                preloadKey.updateDownloadStatus(isSucc)
            }
            // 如果错误码是无权限，更新当前缓存信息，避免再次预加载
            if code == PreloadErrorCode.ClientVarsNoPermission.rawValue {
                self.requestPermissionCacahe.updateValue(RequestPermissionResult(hasRequestPermission: true, hasPermission: false), forKey: preloadKey.objToken)
                self.throttle.schedule({ [weak self] in
                    self?.syncPermissionToFile()
                }, jobId: "preloadPermisisonJob")
            }
            completionHandler(succ && (shouldContinue || isManuOffline))
        }
        task.stateChangeTask = { [weak self] status in
            guard self != nil else { return }
            if isManuOffline {
                preloadKey.updateDownloadStatus(status)
            }
        }
        return task
    }
}

// MARK: - SSR预加载
extension DocPreloaderManager {
    private func preloadSSRTaskNotDependenceClientVars(preloadKey: PreloadKey, enqueueTime: TimeInterval, waitScheduleTime: TimeInterval) {
        var usePreloadKey = preloadKey
        if UserScopeNoChangeFG.GXY.wikiDocxSSRQueueEnable, let wikiKey = preloadKey.wikiRealPreloadKey {
            usePreloadKey = wikiKey
            usePreloadKey.fromSource = preloadKey.fromSource
            DocsLogger.info("wiki-docx SSR", component: LogComponents.preload)
        }
        switch usePreloadKey.type {
        case .docX:
            let fileToken = usePreloadKey.objToken
            self.pauseSubBlockTasks()
            var subPreloadState: SubBlockPreloadState = SubBlockPreloadState()
            if self.preloadState.value(ofKey: fileToken) == nil {
                self.preloadState.updateValue(subPreloadState, forKey: fileToken)
            } else {
                subPreloadState = self.preloadState.value(ofKey: fileToken)!
            }
            if subPreloadState.htmlNativeRequestCount < OpenAPI.docs.ssrPreloadRetryMaxCount {
                var htmlNativePreloadTask = preloadKey.makeNativeHtmlTask(canUseCarrierNetwork: !OpenAPI.RecentCacheConfig.isPreloadClientVarOnlyInWifi, enqueueTime: enqueueTime, waitScheduleTime: waitScheduleTime, preloadQueue: preloadKey.wikiRealPreloadKey != nil ? self.wikiHtmlNativePreloaderQueue.executeQueue() : self.htmlNativePreloaderQueue.executeQueue())
                htmlNativePreloadTask.finishTask = { [weak self] loadErr in
                    guard let self = self else { return }
                    DocsLogger.info("ssr preload \(preloadKey) finish", component: LogComponents.preload)
                    if loadErr == PreloadErrorCode.SSRNotFound.rawValue
                        || loadErr == PreloadErrorCode.SSRNoPermission.rawValue
                        || loadErr == PreloadErrorCode.DocsDeleted.rawValue {
                        subPreloadState.htmlNativeRequestCount += OpenAPI.docs.ssrPreloadRetryMaxCount
                        // 如果错误码是无权限或者不存在，更新权限缓存信息，避免再次预加载
                        self.requestPermissionCacahe.updateValue(RequestPermissionResult(hasRequestPermission: true, hasPermission: false), forKey: fileToken)
                        self.throttle.schedule({ [weak self] in
                            self?.syncPermissionToFile()
                        }, jobId: "preloadPermisisonJob")
                        if UserScopeNoChangeFG.GXY.addPreloadColToRawTableEnable {
                            // 更新数据库中preload字段，不再触发闲时预加载
                            if let renderKey = DocsType.docX.htmlCachedKey, let prefix = User.current.info?.cacheKeyPrefix {
                                self.newCache?.updateNeedPreloadBy(H5DataRecordKey(objToken: fileToken, key: prefix + renderKey), needPreload: false, doctype: .docX)
                            }
                        }
                    } else {
                        subPreloadState.htmlNativeRequestCount += 1
                    }
                    self.preloadState.updateValue(subPreloadState, forKey: fileToken)
                    self.removeTaskFromSaveList(key: preloadKey, preloadClientVars: false)
                }
                
                htmlNativePreloadTask.willStartTask = { [weak self] in
                    guard let self = self else { return }
                    DocsLogger.info("ssr will preload \(preloadKey)", component: LogComponents.preload)
                    if preloadKey.wikiRealPreloadKey == nil {
                        self.preloadSSREnqueueTimeCacahe.updateValue(Date().timeIntervalSince1970, forKey: preloadKey.objToken)
                    }
                }
                if preloadKey.wikiRealPreloadKey != nil {
                    self.wikiHtmlNativePreloaderQueue.addTasks([htmlNativePreloadTask])
                } else {
                    preloadSSREnqueueTimeCacahe.updateValue(-1, forKey: preloadKey.objToken)
                    self.htmlNativePreloaderQueue.addTasks([htmlNativePreloadTask])
                }
                var saveKey = preloadKey
                saveKey.updatePreloadSSR(true)
                self.updateSaveToFileTask(saveKey)
            }
        default:
            DocsLogger.info("wait for clientVars preloaded", component: LogComponents.preload)
        }
    }
}

// MARK: - SubBlocks预加载
extension DocPreloaderManager {
    private func preloadSubBlocksTask(preloadKey: PreloadKey, enqueueTime: TimeInterval) {
        var usePreloadKey = preloadKey
        if let wikiKey = preloadKey.wikiRealPreloadKey {
            usePreloadKey = wikiKey
            usePreloadKey.fromSource = preloadKey.fromSource
            DocsLogger.info("wiki-docx SubBlocks", component: LogComponents.preload)
        }
        let fileToken = usePreloadKey.objToken
        var subPreloadState: SubBlockPreloadState = SubBlockPreloadState()
        if self.preloadState.value(ofKey: fileToken) == nil {
            self.preloadState.updateValue(subPreloadState, forKey: fileToken)
        } else {
            subPreloadState = self.preloadState.value(ofKey: fileToken)!
        }
        switch usePreloadKey.type {
        case .docX:
            if !self.specialFileToken.contains(fileToken) {
                let pictureTask = usePreloadKey.makePictureTask(canUseCarrierNetwork: !OpenAPI.RecentCacheConfig.preloadPictureWifiOnly, enqueueTime: enqueueTime, preloadQueue: self.picturePreloaderQueue.executeQueue())
                self.picturePreloaderQueue.addTasks([pictureTask])
            }
        default:
            if !self.specialFileToken.contains(fileToken) {
                let pictureTask = usePreloadKey.makePictureTask(canUseCarrierNetwork: !OpenAPI.RecentCacheConfig.preloadPictureWifiOnly, enqueueTime: enqueueTime, preloadQueue: self.picturePreloaderQueue.executeQueue())
                self.picturePreloaderQueue.addTasks([pictureTask])
            }
            if !subPreloadState.votePreload {
                var votePreloaderTask = usePreloadKey.makeVoteTask(preloadQueue: self.votePreloaderQueue.executeQueue(), delegate: self.docRNPreloader, enqueueTime: enqueueTime)
                votePreloaderTask.finishTask = {
                    DocsLogger.info("preload subblock\(preloadKey)success", component: LogComponents.preload)
                    subPreloadState.votePreload = true
                    self.preloadState.updateValue(subPreloadState, forKey: fileToken)
                }
                self.votePreloaderQueue.addTasks([votePreloaderTask])
            }
            if !subPreloadState.commentPreload {
                var commentPreloaderTask = usePreloadKey.makeCommentTask(preloadQueue: self.commentPreloaderQueue.executeQueue(), delegate: self.docRNPreloader, enqueueTime: enqueueTime)
                commentPreloaderTask.finishTask = {
                    DocsLogger.info("preload subblock\(preloadKey)success", component: LogComponents.preload)
                    subPreloadState.commentPreload = true
                    self.preloadState.updateValue(subPreloadState, forKey: fileToken)
                }
                self.commentPreloaderQueue.addTasks([commentPreloaderTask])
            }

            guard usePreloadKey.type == .doc else {
                return
            }
            ///canUseCarrierNetwork跟isPreloadClientVar保持一致
            var htmlPreloadTask = usePreloadKey.makeHtmlTask(canUseCarrierNetwork: !OpenAPI.RecentCacheConfig.isPreloadClientVarOnlyInWifi, enqueueTime: enqueueTime, preloadQueue: self.htmlPreloaderQueue.executeQueue())
            htmlPreloadTask.finishTask = {
                DocsLogger.info("preload html subblock\(preloadKey)success", component: LogComponents.preload)
                subPreloadState.htmlPreload = true
                self.preloadState.updateValue(subPreloadState, forKey: fileToken)
            }
            if !subPreloadState.htmlPreload {
                if self.isReadyJS.value == true {
                    self.htmlPreloaderQueue.addTasks([htmlPreloadTask])
                } else {
                    if self.preloadHtmlArray == nil {
                        self.preloadHtmlArray = Array()
                    }
                    DocsLogger.info("preload html js not ready", component: LogComponents.preload)
                    self.preloadHtmlArray?.append(htmlPreloadTask)
                }
            }
        }
    }
}

// MARK: - docx版本预加载
extension DocPreloaderManager {
    private func preloadDocsVersions(token: String, type: DocsType, version: String) {
        func _preload(by key: PreloadKey) {
            DocsLogger.info("loadContent preload version start", component: LogComponents.preload)
            self.add([key], to: self.clientVarPreloaderQueueForLark)
        }
        // 先获取版本token,之后用版本token进行预加载
        DocsVersionManager.shared.getVersionTokenWith(token: token, type: type, version: version, needRequest: true) { vToken, _, _, _ in
            guard let fileToken = vToken else {
                return
            }
            let preloadKey = PreloadKey(objToken: fileToken, type: type)
            _preload(by: preloadKey)
        }
    }
}

// MARK: - 预加载统一框架
extension DocPreloaderManager {
    private func canUsePreloadCentralized() -> Bool {
        // 业务FG和预加载框架FG同时生效
        guard UserScopeNoChangeFG.GXY.docsFeedPreloadCentralizedEnable,
              PreloadMananger.shared.preloadEnable() else {
            return false
        }
        return true
    }
    
    private func preloadTaskName(_ name: String) -> String {
        return "lark_ccm_preload_" + name
    }
    
    private func idelPreloadTaskName(_ name: String) -> String {
        return "lark_ccm_idle_preload_" + name
    }
    
    private func lowDeviceCanPreload() -> Bool {
        return OpenAPI.docs.lowDeviceCanPreload
    }
    
    public func registerIdelTask(preloadName: String, action: @escaping () -> Void) -> Bool {
        guard self.canUsePreloadCentralized() else {
            return false
        }
        PreloadMananger.shared.registerTask(preloadName: self.idelPreloadTaskName(preloadName) , preloadMoment:  PreloadMoment.runloopIdle, biz: PreloadBiz.CCM, preloadType: .OtherType, hasFeedback: false, taskAction: {
            DocsLogger.info("schedule \(preloadName) from centralized idel task", component: LogComponents.preload)
            action()
        }, stateCallBack: nil, lowDeviceEnable: self.lowDeviceCanPreload())
        return true
    }
    
    public func preloadFeedback(_ token: String, hitPreload: Bool) {
        guard canUsePreloadCentralized() else {
            return
        }
        PreloadMananger.shared.feedbackForDiskCache(diskCacheId: token, preloadBiz: .CCM, preloadType: .DocsType, hitPreload: hitPreload)
    }
}

// MARK: - 闲时SSR预加载
extension DocPreloaderManager {
    
    public func IdlePreloadDocs(_ urlString: String) {
        if canUsePreloadCentralized() {
            PreloadMananger.shared.registerTask(preloadName: self.idelPreloadTaskName("preloadAfterCloseDocs"), preloadMoment:  PreloadMoment.runloopIdle, biz: PreloadBiz.CCM, preloadType: .OtherType, hasFeedback: false, taskAction: {
                DocsLogger.info("schedule from preloadAfterCloseDocs centralized idel task", component: LogComponents.preload)
                self.loadContent(urlString, from: FromSource.ssrIdelpreload.rawValue)
            }, stateCallBack: nil, lowDeviceEnable: self.lowDeviceCanPreload())
        } else {
            RunloopDispatcher.shared.addTask(priority: .low) { [weak self] in
            DocsLogger.info("cpu.task: idleSSRPreloadAfterCloseDocs", component: LogComponents.preload)
            self?.loadContent(urlString, from: FromSource.ssrIdelpreload.rawValue)
            }.waitCPUFree().withIdentify("leisureAsyncStage-preloadAfterCloseDocs")
        }
    }
    
    private func registerIdleSSRPreloadtask() {
        guard UserScopeNoChangeFG.GXY.docxSSRIdelPreloadEnable else {
            return
        }
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return
        }
        if dataCenterAPI.hadLoadDBForCurrentUser {
            /// 预加载统一框架
            if canUsePreloadCentralized() {
                PreloadMananger.shared.registerTask(preloadName: self.idelPreloadTaskName("ssrDataPreapare"), preloadMoment:  PreloadMoment.runloopIdle, biz: PreloadBiz.CCM, preloadType: .OtherType, hasFeedback: false, taskAction: {
                    DocsLogger.info("schedule from ssrDataPreapare centralized idel task", component: LogComponents.preload)
                    self.idleSSRDatePreapare()
                }, stateCallBack: nil, lowDeviceEnable: self.lowDeviceCanPreload())
            } else {
                RunloopDispatcher.shared.addTask(priority: .low) { [weak self] in
                    DocsLogger.info("cpu.task: idleSSRDataPreapare", component: LogComponents.preload)
                    self?.idleSSRDatePreapare()
                }.waitCPUFree().withIdentify("leisureAsyncStage-ssrDataPreapare")
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                self.registerIdleSSRPreloadtask()
            }
        }
    }
    
    private func idleSSRDatePreapare() {
        if idleSSRDataPrepared == false , UserScopeNoChangeFG.GXY.docxSSRIdelPreloadEnable {
            let idelSSRdata =  newCache?.getNoSSRTokens(count: DocPreloaderManager.preloadSSRNumber, doctype: .docX, queryMaxCount: DocPreloaderManager.preloadSSRQueryMaxNumber, limitDaysCount: DocPreloaderManager.preloadQueryDaysNumber)
            var idleDataArray: [PreloadKey] = []
            idelSSRdata?.forEach({ record in
                var preloadKey = PreloadKey(objToken: record.objToken, type: .docX)
                preloadKey.fromSource = PreloadFromSource(.ssrIdelpreload)
                preloadKey.loadPriority = .low
                idleDataArray.append(preloadKey)
            })
            idleSSRDataArray = idleDataArray
            DocsLogger.info("idleSSR Data ready：\(String(describing: idleSSRDataArray?.count))", component: LogComponents.preload)
            idleSSRDataPrepared = true
        }
    }
    
    private func startIdleSSRPreload() {
        func _preload(by key: PreloadKey) {
            DocsLogger.info("startIdleSSRPreload start", component: LogComponents.preload)
            self.add([key], to: self.clientVarPreloaderQueueForLark)
        }
        self.preloadQueue.async { [weak self] in
            guard let self = self else { return }
            if let firstElement = self.idleSSRDataArray?.first {
                self.idleSSRDataArray?.remove(at: 0)
                _preload(by: firstElement)
            }
        }
    }
    
    private static var preloadSSRNumber: Int {
        return SettingConfig.offlineCacheConfig?.ssrPreloadCount ?? 10
    }
    
    private static var preloadSSRQueryMaxNumber: Int {
        return SettingConfig.offlineCacheConfig?.ssrPreloadQueryMaxCount ?? 100
    }
    
    private static var preloadQueryDaysNumber: Int {
        return SettingConfig.offlineCacheConfig?.ssrPreloadQueryDays ?? 30
    }
    
    private func addIdlePreloadSSRDataTask() {
        self.preloadQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.idleSSRDataPrepared else {
                return
            }
            guard self.idleSSRDataArray?.count ?? 0 > 0 else {
                return
            }
            /// 预加载统一框架
            if self.canUsePreloadCentralized() {
                PreloadMananger.shared.registerTask(preloadName: self.idelPreloadTaskName("ssrPreload"), preloadMoment:  PreloadMoment.runloopIdle, biz: PreloadBiz.CCM, preloadType: .OtherType, hasFeedback: false, taskAction: {
                    DocsLogger.info("schedule from ssrPreload centralized idel task", component: LogComponents.preload)
                    self.startIdleSSRPreload()
                }, stateCallBack: nil, lowDeviceEnable: self.lowDeviceCanPreload())
            } else {
                RunloopDispatcher.shared.addTask(priority: .low) { [weak self] in
                    DocsLogger.info("cpu.task: idleSSRPreload", component: LogComponents.preload)
                    self?.startIdleSSRPreload()
                }.waitCPUFree().withIdentify("leisureAsyncStage-ssrPreload")
            }
        }
    }
}

// MARK: - 任务优先级
extension DocPreloaderManager {
    private func preloadPriority(type: DocsType, from: PreloadFromSource?) -> PreloadPriority {
        guard UserScopeNoChangeFG.GXY.docxPreloadTaskPriorityEnable else {
            return .middle
        }
        
        guard let fromSource = from else {
            return .middle
        }
        
        guard let config = SettingConfig.DocsPreloadPriorityConfig else {
            return .middle
        }
        
        if config.keys.firstIndex(of: type.name) != nil {
            if let dic = config[type.name] as? [String: Any],
               let priority = dic[fromSource.rawValue] as? String {
                if priority == "high" {
                    return .high
                } else if priority == "low" {
                    return .low
                } else {
                    return .middle
                }
            }
        }
        
        return .middle
    }
}

// MARK: - 权限判断
extension DocPreloaderManager {
    func fetchPermission(preloadKey: PreloadKey, waitRequestResult: Bool = true, completionHandler:@escaping (Bool) -> Void) {
        // 进入这一步后，走 wiki 内部文档的加载流程，排除 wiki 类型的影响
        let preloadKey = preloadKey.wikiRealPreloadKey ?? preloadKey
        let fileToken = preloadKey.objToken
        if requestPermissionCacahe.value(ofKey: fileToken) == nil {
            requestPermissionCacahe.updateValue(RequestPermissionResult(hasRequestPermission: false, hasPermission: false), forKey: fileToken)
        }
        let hasRequest = requestPermissionCacahe.value(ofKey: fileToken)?.hasRequestPermission ?? false
        let hasPermission = requestPermissionCacahe.value(ofKey: fileToken)?.hasPermission ?? false
        if hasRequest {
            // 上报命中缓存的统计记录
            let record = PreloadDataRecord(fileID: preloadKey.encryptedObjToken, preloadFrom: preloadKey.fromSource, waitScheduleTime: 0)
            record.updateInitInfo(loaderType: .Native, fileType: preloadKey.type, subFileType: preloadKey.wikiRealPreloadKey?.type, loadType: .permission, retry: 0)
            record.endRecord(cache: true)
            completionHandler(hasPermission)
            // 检查是否需要去更新
            checkNeedUpdatePermission(preloadKey)
            return
        }
        // 如果不等待权限结果，默认返回true有权限
        if waitRequestResult == false {
            completionHandler(true)
        } else {
            var requestResult = requestPermissionCacahe.value(ofKey: fileToken) ?? RequestPermissionResult(hasRequestPermission: false, hasPermission: false)
            // 如果已经在请求中了，不需要再次查询
            if requestResult.hasRequestPermission {
                return
            }
            requestResult.updateHasRequestPermission(hasRequestPermission: true)
            self.requestPermission(preloadKey) { hasPermission in
                completionHandler(hasPermission)
            }
        }
    }
    
    // 异步线程从文件读取上次的权限缓存
    private func readPermissionFromFile() {
        permissionUpdateQueue.async {
            let savePath = SKFilePath.preloadPermissionCachePath
            guard let content = try? Data.read(from: savePath) else {
                return
            }
            let data: Data = content
            guard let any = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else {
                return
            }
            guard let dic = any as? [String: Any] else {
                return
            }
            // 检查文档更新时间，超过有效期，清理文档
            guard let modification = savePath.fileAttribites[FileAttributeKey.modificationDate] as? NSDate else {
                DocsLogger.info("readPermission file'time error", component: LogComponents.preload)
                try? savePath.removeItem()
                return
            }
            // 权限缓存有效期配置下发
            if (NSDate().timeIntervalSince1970 - modification.timeIntervalSince1970) >= OpenAPI.docs.docsPreloadTimeOut {
                DocsLogger.info("readPermission remove cacheFile for time‘s out", component: LogComponents.preload)
                try? savePath.removeItem()
                return
            }
            DocsLogger.info("readPermission from file success", component: LogComponents.preload)
            dic.keys.forEach { key in
                if self.requestPermissionCacahe.value(ofKey: key) == nil {
                    self.requestPermissionCacahe.updateValue(RequestPermissionResult(hasRequestPermission: true, hasPermission: dic[key] as? Bool ?? true), forKey: key)
                    self.needUpdatePermissionCache.insert(key)
                }
            }
        }
    }
    
    private func syncPermissionToFile() {
        permissionUpdateQueue.async {
            let savePath = SKFilePath.preloadPermissionCachePath
            _ = savePath.createFileIfNeeded(with: nil)
            var saveDic = [String: Any]()
            self.requestPermissionCacahe.enumerateObjectUsingBlock { key, value in
                if value.hasRequestPermission {
                    saveDic[key] = value.hasPermission
                }
            }
            guard let data = try? JSONSerialization.data(withJSONObject: saveDic, options: []) else {
                DocsLogger.warning("PermissionConvertToData Fail", component: LogComponents.preload)
                return
            }
            do {
                try savePath.set(fileAttributes: [FileAttributeKey.modificationDate: Date()])
                try data.write(to: savePath)
            } catch let error {
                let errmsg: String = {
                    let nsErr = error as NSError
                    return "\(nsErr.code):\(nsErr.domain)"
                }()
                DocsLogger.error("save Permission to file fail, err=\(errmsg)", component: LogComponents.preload)
                try? savePath.removeItem()
            }
        }
    }
    
    private func checkNeedUpdatePermission(_ preloadKey: PreloadKey ) {
        if needUpdatePermissionCache.count() == 0 {
            return
        }
        if needUpdatePermissionCache.contains(preloadKey.objToken) {
            self.requestPermission(preloadKey, completionHandler: { [weak self] _ in
                self?.needUpdatePermissionCache.remove(preloadKey.objToken)
            })
        }
    }
    
    private func requestPermission(_ preloadKey: PreloadKey, completionHandler:@escaping (Bool) -> Void) {
        guard let permissionManager = DocsContainer.shared.resolve(PermissionManager.self) else { return }
        let fileToken = preloadKey.objToken
        let record = PreloadDataRecord(fileID: preloadKey.encryptedObjToken, preloadFrom: preloadKey.fromSource, waitScheduleTime: 0)
        record.updateInitInfo(loaderType: .Native, fileType: preloadKey.type, subFileType: preloadKey.wikiRealPreloadKey?.type, loadType: .permission, retry: 0)
        record.startRecod()
        requestPermissionRecord.updateValue(record, forKey: fileToken)
        permissionManager.fetchUserPermissions(token: fileToken, type: preloadKey.type.rawValue) { [weak self] info, error in
            guard let `self` = self else { return }
            let record = self.requestPermissionRecord.value(ofKey: fileToken)
            var errCode = PreloadErrorCode.PermissionDefault.rawValue
            if let error = error as NSError? {
                errCode = error.code
            }
            record?.updateResultCode(code: (info != nil) ? 0 : errCode)
            record?.endRecord()
            self.requestPermissionRecord.removeValue(forKey: fileToken)
            guard let info = info else {
                DocsLogger.error("fetch user permission failed.", error: error, component: LogComponents.preload)
                self.requestPermissionCacahe.updateValue(RequestPermissionResult(hasRequestPermission: false, hasPermission: false), forKey: fileToken)
                completionHandler(false)
                return
            }
            let hasPermission = info.mask?.canView() ?? false
            self.requestPermissionCacahe.updateValue(RequestPermissionResult(hasRequestPermission: true, hasPermission: hasPermission), forKey: fileToken)
            self.throttle.schedule({ [weak self] in
                self?.syncPermissionToFile()
            }, jobId: "preloadPermisisonJob")
            DocsLogger.info("fetch user permission hasPermission:\(hasPermission)", component: LogComponents.preload)
            completionHandler(hasPermission)
        }
    }
}

// MARK: - 网络相关
extension DocPreloaderManager {
    
    // 判断是否是弱网
    private func isWeekNetwork() -> Bool {
        let effectiveConnectionType = TTNetworkManager.shareInstance().getEffectiveConnectionType()
        if effectiveConnectionType.rawValue < TTNetEffectiveConnectionType.EFFECTIVE_CONNECTION_TYPE_3G.rawValue {
            return true
        }
        return false
    }
    
}

// MARK: - 预加载任务持久化
extension DocPreloaderManager {
    // 检查FG和ABTest是否可以开启持久化策略
    private func canOpenArchedTask() -> Bool {
        guard UserScopeNoChangeFG.GXY.docxPreloadTaskArchviedEnable else {
            DocsLogger.info("docxPreloadTaskArchvied FG close", component: LogComponents.preload)
            return false
        }
#if DEBUG
        return true
#else
        guard let abEnable = Tracker.experimentValue(key: "docs_preload_arched_enable_ios", shouldExposure: true) as? Int, abEnable == 1 else {
            DocsLogger.info("docxPreloadTaskArchvied ABTest disable", component: LogComponents.preload)
            return false
        }
        return true
#endif
    }
    
    // 是否可以开启持久化任务
    private func checkRecoverArchedTask() {
        guard canOpenArchedTask() else {
           return
        }
        // 预加载统一管理
        if self.canUsePreloadCentralized() {
            PreloadMananger.shared.registerTask(preloadName: self.idelPreloadTaskName("archedPreload"), preloadMoment:  PreloadMoment.runloopIdle, biz: PreloadBiz.CCM, preloadType: .OtherType, hasFeedback: false, taskAction: {
                DocsLogger.info("schedule from archedPreload centralized idel task", component: LogComponents.preload)
                self.recoverPreloadTask()
            }, stateCallBack: nil, lowDeviceEnable: self.lowDeviceCanPreload())
        } else {
            RunloopDispatcher.shared.addTask(priority: .low) { [weak self] in
                DocsLogger.info("cpu.task: archedPreload", component: LogComponents.preload)
                self?.recoverPreloadTask()
            }.waitCPUFree().withIdentify("leisureAsyncStage-archedPreload")
        }
    }
    
    private func addCompleteBlockToQueue () {
        self.htmlNativePreloaderQueue.completeBlock = { [weak self] in
            guard let self = self else { return }
            self.addIdlePreloadSSRDataTask()
            self.checkStartSubBlockTasks()
        }
        self.clientVarPreloaderQueue.completeBlock = { [weak self] in
            guard let self = self else { return }
            self.checkStartSubBlockTasks()
        }
        self.clientVarPreloaderQueueForLark.completeBlock = { [weak self] in
            guard let self = self else { return }
            self.checkStartSubBlockTasks()
        }
        self.clientVarPreloaderQueueForManuOffline.completeBlock = { [weak self] in
            guard let self = self else { return }
            self.checkStartSubBlockTasks()
        }
    }
    
    private func checkStartSubBlockTasks() {
        guard self.htmlNativePreloaderQueue.currentTasksFinished(),
              self.clientVarPreloaderQueue.currentTasksFinished(),
              self.clientVarPreloaderQueueForLark.currentTasksFinished(),
              self.clientVarPreloaderQueueForManuOffline.currentTasksFinished() else {
            DocsLogger.info("not ready, cannot start subBlocks", component: LogComponents.preload)
            return
        }
        self.picturePreloaderQueue.startWholeTask()
        self.votePreloaderQueue.startWholeTask()
        self.commentPreloaderQueue.startWholeTask()
        DocsLogger.info("start subBlocks", component: LogComponents.preload)
    }
    
    private func pauseSubBlockTasks() {
        self.picturePreloaderQueue.pauseWholeTask()
        self.votePreloaderQueue.pauseWholeTask()
        self.commentPreloaderQueue.pauseWholeTask()
        DocsLogger.info("pause subBlocks", component: LogComponents.preload)
    }
    
    // 判断文档类型和from
    private func canArchedTask(type: DocsType, subType: DocsType?, from: PreloadFromSource) -> Bool {
        guard OpenAPI.docs.docsRecoverPreloadTaskSupportTypes.contains(type.name),
              OpenAPI.docs.docsRecoverPreloadTaskSupportFroms.contains(from.rawValue) else {
            DocsLogger.info("docxPreloadTaskArchvied disable:\(type.name) :\(from.rawValue)", component: LogComponents.preload)
            return false
        }
        return true
    }
    
    /// 检查是否可以将预加载任务key加入队列
    private func updateSaveToFileTask(_ key: PreloadKey) {
        guard canOpenArchedTask() else {
            return
        }
        if  canArchedTask(type: key.type, subType: key.wikiRealPreloadKey?.type, from: key.fromSource ?? PreloadFromSource(.other)) {
            addTaskToSaveList(key: key)
        }
    }
    /// 预加载任务key加入队列、维护队列大小并写文件
    private func addTaskToSaveList(key: PreloadKey) {
        let maxCount = OpenAPI.docs.docsRecoverPreloadTaskMaxCount
        if self.saveToFileTasksKeys.count >= maxCount {
            self.saveToFileTasksKeys.removeFirst()
            self.saveToFileTasksKeys.append(key)
            self.savePreloadTaskToFile()
        } else {
            self.saveToFileTasksKeys.append(key)
            self.savePreloadTaskToFile()
        }
    }
    /// 预加载任务key移除队列，写文件
    private func removeTaskFromSaveList(key: PreloadKey, preloadClientVars: Bool) {
        guard canOpenArchedTask() else {
            return
        }
        // 需要ClientVar和SSR预加载流程都走完
        if let index = self.saveToFileTasksKeys.firstIndex(of: key) {
            var key = self.saveToFileTasksKeys[index]
            if preloadClientVars {
                key.updatePreloadClientVars(false)
            } else {
                key.updatePreloadSSR(false)
            }
            if key.preloadSSR == false, key.preloadClientVars == false {
                self.saveToFileTasksKeys.remove(at: index)
                self.savePreloadTaskToFile()
            }
        }
    }
    
    /// 写文件
    private func savePreloadTaskToFile() {
        saveTaskToFileQueue.async {
            let savePath = SKFilePath.preloadTaskSavePath
            _ = savePath.createFileIfNeeded(with: nil)
            var saveDic: [Any] = []
            
            self.saveToFileTasksKeys.forEach { preloadKey in
                var dic: [String: Any] = [:]
                dic["token"] = preloadKey.objToken
                dic["type"] = preloadKey.type.rawValue
                dic["from"] = preloadKey.fromSource?.rawValue ?? ""
                dic["time"] = NSDate().timeIntervalSince1970
                saveDic.append(dic)
            }
            guard let data = try? JSONSerialization.data(withJSONObject: saveDic, options: []) else {
                DocsLogger.warning("PreloadTaskConvertToData Fail", component: LogComponents.preload)
                return
            }
            do {
                try data.write(to: savePath)
            } catch let error {
                let errmsg: String = {
                    let nsErr = error as NSError
                    return "\(nsErr.code):\(nsErr.domain)"
                }()
                DocsLogger.error("save PreloadTask to file fail, err=\(errmsg)", component: LogComponents.preload)
            }
        }
    }
    /// 读文件
    private func recoverPreloadTask() {
        saveTaskToFileQueue.async {
            let savePath = SKFilePath.preloadTaskSavePath
            guard let content = try? Data.read(from: savePath) else {
                return
            }
            let data: Data = content
            guard let any = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else {
                return
            }
            guard let array = any as? [Any] else {
                return
            }
            
            DocsLogger.info("readArchedTask from file success", component: LogComponents.preload)
            var loadKeyArray: [PreloadKey] = []
            array.forEach { obj in
                if let dic = obj as? [String: Any] {
                    if let objToken = dic["token"] as? String,
                        let type = dic["type"] as? Int {
                        guard let time = dic["time"] as? TimeInterval, (NSDate().timeIntervalSince1970 - time) <=  OpenAPI.docs.docsRecoverLastPreloadTaskTimeOut else {
                            DocsLogger.info("readArchedTask is timeout", component: LogComponents.preload)
                            return
                        }
                        guard let from = dic["from"] as? String else {
                            DocsLogger.info("archedTask from nil", component: LogComponents.preload)
                            return
                        }
                        let fromSource = PreloadFromSource(rawValue: from)
                        guard self.canArchedTask(type: DocsType(rawValue: type), subType: nil, from: fromSource) else {
                            DocsLogger.info("readArchedTask from forbiden", component: LogComponents.preload)
                            return
                        }
                        if DocsType(rawValue: type) == .wiki {
                            self.resolver?.resolve(SKCommonDependency.self)!
                                .setWikiMeta(wikiToken: objToken) { (wikiInfo, error) in
                                    guard let wikiInfo = wikiInfo else {
                                        DocsLogger.warning("wiki preload by url failed: \(String(describing: error))", component: LogComponents.preload)
                                        return
                                    }
                                    guard  wikiInfo.docsType != .file else {
                                        DocsLogger.warning("file not support preload clientVar", component: LogComponents.preload)
                                        return
                                    }
                                    var preloadKey: PreloadKey
                                    if wikiInfo.spaceId.isEmpty {
                                        // spaceId 为空表明文档已经不在 wiki 了，后续预加载改为预加载文档本体
                                        preloadKey = PreloadKey(objToken: wikiInfo.objToken, type: wikiInfo.docsType)
                                    } else {
                                        preloadKey = PreloadKey(objToken: objToken, type: DocsType(rawValue: type), wikiInfo: wikiInfo)
                                    }
                                    preloadKey.fromSource = PreloadFromSource(.archedPreload)
                                    preloadKey.loadPriority = .low
                                    self.add([preloadKey], to: self.clientVarPreloaderQueue)
                                }
                        } else {
                            var preloadKey = PreloadKey(objToken: objToken, type: DocsType(rawValue: type))
                            preloadKey.fromSource = PreloadFromSource(.archedPreload)
                            preloadKey.loadPriority = .low
                            loadKeyArray.append(preloadKey)
                        }
                    }
                }
            }
            self.add(loadKeyArray, to: self.clientVarPreloaderQueue)
            try? savePath.removeItem()
        }
    }
}
