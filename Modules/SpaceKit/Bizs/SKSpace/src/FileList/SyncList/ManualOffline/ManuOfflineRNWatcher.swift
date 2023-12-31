//
//  ManuOfflineRNWatcher.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/21.
//  
// 手动离线和RN打交道

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra
import LarkContainer

public protocol RNWatchBaseProtocol: RNMessageDelegate {
    func userDidLogout()
    func userDidLogin()
    var isInForground: Bool { get set }
}

public enum RNWatchType: String {
    case META
    case OFFLINE
}

public protocol ManuOfflineRNWatcherAPI: RNWatchBaseProtocol {
}

final class ManuOfflineRNWatcher: ManuOfflineRNWatcherAPI {
    private let queue = DispatchQueue(label: "docs.bytedanece.net.ManuOfflineRNWatcher")
    private weak var resolver: DocsResolver?

    lazy private var fileManuOfflineManager: FileManualOfflineManagerAPI? = resolver?.resolve(FileManualOfflineManagerAPI.self)
    lazy private var rnManager = resolver?.resolve(RNMangerAPI.self)
    lazy private var preloader: DocPreloaderManagerAPI? = {
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        return ur.docs.docPreloaderManagerAPI
    }()
    private var unWatchRequestCount = 0
    private var watchRequestCount = 0

    /// 已经成功watch的token
    private var watchSuccessKeys = Set<ManuOfflineKey>() {
        didSet {
            docExpectOnQueue(queue)
        }
    }

    /// 已经发出请求，还没有返回的token
    private var sentKeys = Set<ManuOfflineKey>() {
        didSet {
            docExpectOnQueue(queue)
        }
    }

    /// 需要被watch的token
    private var needWatchKeys = Set<ManuOfflineKey>() {
        didSet {
            docExpectOnQueue(queue)
        }
    }

    /// 记录失败的key和type，避免无限请求
    private var failedKeysCountMap = [ManuOfflineKey: UInt]()
    private let maxRetryCount = 3

    var isInForground = true {
        didSet {
            guard isInForground != oldValue else {
                return
            }
            queue.async {
                if self.isInForground {
                    self.startSync()
                } else {
                    self.toggle(isWatch: false, keys: self.watchSuccessKeys)
                }
            }
        }
    }

    init(_ resolver: DocsResolver = DocsContainer.shared) {
        self.resolver = resolver
        queue.async {
            self.rnManager?.registerRnEvent(eventNames: [.getDataFromRN], handler: self)
            self.fileManuOfflineManager?.addObserver(self)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.rnReloadComplete), name: Notification.Name.Docs.rnReloadComplete, object: nil)
    }

    @objc
    private func rnReloadComplete() {
        queue.async {
            if self.isInForground {
                self.failedKeysCountMap.removeAll()
                self.watchSuccessKeys.removeAll()
                self.sentKeys.removeAll()
                self.startSync()
                DocsLogger.info("rnReloadComplete, tryToStartSync")
            }
        }
    }

    func userDidLogout() {
        queue.async {
            self.needWatchKeys.removeAll()
            self.failedKeysCountMap.removeAll()
            self.toggle(isWatch: false, keys: self.watchSuccessKeys)
        }
    }

    func userDidLogin() {
        queue.async {
            self.fileManuOfflineManager?.addObserver(self)
            if self.isInForground {
                self.startSync()
            }
        }
    }

    func didReceivedRNData(data outData: [String: Any], eventName: RNManager.RNEventName) {
        guard eventName == .getDataFromRN else {
            return
        }
        DocsLogger.debug("didReceivedRNData? \(outData))", component: LogComponents.manuOffline)

        guard let data = outData["data"] as? [String: Any] else {
            return
        }
        guard let action = data["action"] as? String else {
            return
        }

        let innerData = JSON(data["data"] as Any)
        let extraType = innerData["extra"]["type"].stringValue

        if extraType == RNWatchType.OFFLINE.rawValue ||
            extraType.isEmpty {

            if action == "offWatchDriveUpdate" ||
                action == "offUnwatchResult" ||
                action == "offWatchResult" ||
                action == "offWatchEntityDeleted" ||
                action == "offWatchEntityPermission" {
                DocsLogger.info("getDataFromRN action =\(action))", component: LogComponents.manuOffline)
                queue.async {
                    switch action {
                    case "offWatchDriveUpdate":
                        self.handleOffWatchDriveUpdate(innerData)
                    case "offUnwatchResult":
                        self.handleToggleWatch(isWatch: false, result: innerData)
                    case "offWatchResult":
                        self.handleToggleWatch(isWatch: true, result: innerData)
                    case "offWatchEntityDeleted":
                        self.handleWatchEntityDeleted(innerData)
                    case "offWatchEntityPermission": // 权限被收回了: 清理缓存 & 保留Space列表入口
                        self.handleWatchEntityDeleted(innerData, deleteInList: false)
                    default:
                        return
                    }
                }
            }
        } else {
            DocsLogger.info("watch rn extraType=\(extraType))", component: LogComponents.manuOffline)
        }
    }
}

private extension ManuOfflineRNWatcher {

    private func handleToggleWatch(isWatch: Bool, result: JSON) {
        docExpectOnQueue(queue)
        if isWatch {
            watchRequestCount += 1
        } else {
            unWatchRequestCount += 1
        }
        sentKeys.removeAll()

        let arrayJson = result["tokens"]
        arrayJson.array?.forEach { json in
            guard let objToken = json["token"].string,
                let rawType = json["type"].int else {
                    return
            }
            let type = DocsType(rawValue: rawType)
            if type.isUnknownType { return }
            let key = ManuOfflineKey(objToken: objToken, type: type)
            let succ = json["succ"].boolValue
            if succ {
                if isWatch {
                    watchSuccessKeys.insert(key)
                } else {
                    watchSuccessKeys.remove(key)
                }
            } else {
                failedKeysCountMap[key] = (failedKeysCountMap[key] ?? 0) + 1
            }
            DocsLogger.info("toggle watch: \(isWatch) success? \(succ) \(key.description))", component: LogComponents.manuOffline)
        }
        startSync()
    }

    private func handleOffWatchDriveUpdate(_ result: JSON) {
        docExpectOnQueue(queue)
        guard let typeRaw = result["type"].int,
            let objToken = result["token"].string else {
                DocsLogger.info("handleOffWatchDriveUpdate param not right", component: LogComponents.manuOffline)
                return
        }
        let type = DocsType(rawValue: typeRaw)
        if type.isUnknownType { return }
        spaceAssert(type == .file, "type is \(type.rawValue)")
        let manuOfflineFile = ManualOfflineFile(objToken: objToken, type: type)
        DocsLogger.info("handleOffWatchDriveUpdate \(DocsTracker.encrypt(id: objToken)))", component: LogComponents.manuOffline)
        fileManuOfflineManager?.refreshOfflineData(of: manuOfflineFile)
    }

    private func handleWatchEntityDeleted(_ result: JSON, deleteInList: Bool = true) {
        docExpectOnQueue(queue)
        let arrayJson = result["tokens"]
        arrayJson.array?.forEach { json in
            guard let objToken = json["token"].string,
                let rawType = json["type"].int else {
                    return
            }
            let type = DocsType(rawValue: rawType)
            if type.isUnknownType { return }
            /// wiki类型文档根据返回的实体token寻找对应的wikiToken, 无wikiToken则作为正常space文档处理
            let wikiToken = needWatchKeys.first { $0.wikiInfo?.objToken == objToken }?.wikiInfo?.wikiToken
            /// 删除列表页数据
            if deleteInList {
                SKDataManager.shared.deleteFileByToken(token: TokenStruct(token: wikiToken ?? objToken))
                NotificationCenter.default.post(name: .Docs.deleteDocInNewHome, object: wikiToken ?? objToken)
            } else {
                let token = wikiToken ?? objToken
                SKDataManager.shared.updateUIModifier(tokenInfos: [token : SyncStatus(upSyncStatus: .none, downloadStatus: .none)])
            }

            /// 同时通知drive 那边删除缓存
            let file = ManualOfflineFile(objToken: objToken, type: type)
            let extraData: [ManualOfflineCallBack.ExtraKey: Any] = [.entityDeleted: true]
            fileManuOfflineManager?.removeFromOffline(by: file, extra: extraData)

            DocsLogger.info("watchEntityDeleted \(DocsTracker.encrypt(id: objToken)))", component: LogComponents.manuOffline)
        }
    }

    private func toggle(isWatch: Bool, keys: Set<ManuOfflineKey>) {
        docExpectOnQueue(queue)
        if keys.isEmpty {
            return
        }
        let bodyData = keys.map {
            return ["type": $0.type.rawValue, "token": $0.objToken ]
        }
        let data: [String: Any] = [
            "operation": isWatch ? "offWatch" : "offUnwatch",
            "body": bodyData,
            "extra": ["type": RNWatchType.OFFLINE.rawValue]
        ]
        let composedData: [String: Any] = ["business": "base",
                                           "data": data]
        rnManager?.sendSpaceBusnessToRN(data: composedData)
        DocsLogger.info("toggle watch \(isWatch) \(keys.map({ $0.description }))", component: LogComponents.manuOffline)

        //超时逻辑
        let currentCount = isWatch ? watchRequestCount : unWatchRequestCount
        // nolint-next-line: magic number
        queue.docAsyncAfter(50) { [weak self] in
            guard let self = self else { return }
            let isOvertime: Bool = {
                if isWatch {
                    return self.watchRequestCount == currentCount
                } else {
                    return self.unWatchRequestCount == currentCount
                }
            }()
            if isOvertime {
                DocsLogger.info("toggle watch \(isWatch) overtime \(keys.map({ $0.description }))", component: LogComponents.manuOffline)
                self.sentKeys.removeAll()
                keys.forEach { key in
                    self.failedKeysCountMap[key] = (self.failedKeysCountMap[key] ?? 0) + 1
                }
                self.startSync()
            }
        }
    }

    /// 比较needWatch 和 watchSuccess，然后发出对应的请求到RN
    private func startSync() {
        docExpectOnQueue(queue)
        guard isInForground else {
            return
        }
        if !sentKeys.isEmpty {
            DocsLogger.info("sentKeys is not Empty, do not send", component: LogComponents.manuOffline)
        }
        let retryOverTimeKeys = failedKeysCountMap.filter({ $0.value >= maxRetryCount }).keys
        let needSendWatchSet = needWatchKeys.subtracting(watchSuccessKeys).subtracting(retryOverTimeKeys)
        let needSendUnwatchSet = watchSuccessKeys.subtracting(needWatchKeys).subtracting(retryOverTimeKeys)

        if !needSendWatchSet.isEmpty {
            sentKeys = needSendWatchSet
            toggle(isWatch: true, keys: sentKeys)
        } else if !needSendUnwatchSet.isEmpty {
            sentKeys = needSendUnwatchSet
            toggle(isWatch: false, keys: sentKeys)
        } else {
            DocsLogger.info("no Need watch or unwatch", component: LogComponents.manuOffline)
        }
    }

    private func addNeedSyncKeys(_ keys: Set<ManuOfflineKey>) {
        docExpectOnQueue(queue)
        keys.forEach { key in
            if key.objToken.isEmpty {
                DocsLogger.error("key.objToken.isEmpty", component: LogComponents.manuOffline)
                return
            }
            self.needWatchKeys.insert(key)
            self.failedKeysCountMap[key] = nil
        }
        if self.sentKeys.isEmpty {
            self.startSync()
        }
        let needPreloadkeys = keys.map({ $0.toPreloadKey }).filter { $0.type != .file }
        preloader?.addManuOfflinePreloadKey(needPreloadkeys)
    }

    private func removeNeedSyncKeys(_ keys: Set<ManuOfflineKey>) {
        docExpectOnQueue(queue)
        keys.forEach { key in
            if key.objToken.isEmpty {
                return
            }
            self.needWatchKeys.remove(key)
            self.failedKeysCountMap[key] = nil
        }
        if self.sentKeys.isEmpty {
            self.startSync()
        }
    }

    private func notifyRNOpenStatus(_ action: ManualOfflineAction) {
        docExpectOnQueue(queue)
        let operation1: String? = {
            switch action.event {
            case .startOpen: return "enterInSuite"
            case .endOpen: return "exitFromSuite"
            default: return nil
            }
        }()
        guard let operation = operation1 else { return }

        let bodyData = action.files.map {
            return ["type": $0.type.rawValue, "token": $0.objToken ]
        }
        let data: [String: Any] = ["operation": operation,
                                   "body": bodyData]
        let composedData: [String: Any] = ["business": "base",
                                           "data": data]
        rnManager?.sendSpaceBusnessToRN(data: composedData)
        DocsLogger.info("notifyRNOpenStatus \(operation) \(action.files.map({ DocsTracker.encrypt(id: $0.objToken) }))", component: LogComponents.manuOffline)
    }
}

extension ManuOfflineRNWatcher: ManualOfflineFileStatusObserver {
    func didReceivedFileOfflineStatusAction(_ action: ManualOfflineAction) {
        queue.async {
            switch action.event {
            case .add, .update, .netStateChanged:
                let keys = action.files.map { ManuOfflineKey(objToken: $0.objToken, type: $0.type, wikiInfo: $0.wikiInfo) }
                self.addNeedSyncKeys(Set(keys))
            case .remove:
                let keys = action.files.map { ManuOfflineKey(objToken: $0.objToken, type: $0.type, wikiInfo: $0.wikiInfo) }
                self.removeNeedSyncKeys(Set(keys))
            case .startOpen, .endOpen:
                self.notifyRNOpenStatus(action)
            case .refreshData:
                break
            default: ()
            }
        }
    }
}

fileprivate extension ManuOfflineRNWatcher {
    struct ManuOfflineKey: Hashable, CustomStringConvertible {
        let objToken: FileListDefine.ObjToken
        let type: DocsType
        let wikiInfo: WikiInfo?

        var description: String {
            return DocsTracker.encrypt(id: objToken)
        }

        var toPreloadKey: PreloadKey {
            return PreloadKey(objToken: objToken, type: type, wikiInfo: wikiInfo)
        }
        
        init(objToken: FileListDefine.ObjToken, type: DocsType, wikiInfo: WikiInfo? = nil) {
            self.objToken = objToken
            self.type = type
            self.wikiInfo = wikiInfo
        }

        static func == (lhs: ManuOfflineKey, rhs: ManuOfflineKey) -> Bool {
            return lhs.objToken == rhs.objToken && lhs.type == rhs.type
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(objToken)
            hasher.combine(type)
        }
    }
}
