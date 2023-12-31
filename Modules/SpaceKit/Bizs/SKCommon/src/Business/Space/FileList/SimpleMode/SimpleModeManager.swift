//
//  SimpleModeManager.swift
//  SpaceKit
//
//  Created by litao_dev on 2020/2/21.
//  

import Foundation
import SKFoundation
import SpaceInterface
import SKInfra


public protocol SimpleModeProtocol {
    //是否展示精简模式
    func judgeIsNeedShowInSimpleMode(oriShow: Bool) -> Bool
}
extension SimpleModeProtocol where Self: SpaceEntry {
    public func judgeIsNeedShowInSimpleMode(oriShow: Bool) -> Bool {
        guard !DocsConfigManager.isfetchFullDataOfSpaceList else { return oriShow }
        if self.type == .folder { return false }
        if self.openTime == nil { return false }
        if let openTime = self.openTime, openTime <= SimpleModeManager.timeLimit { return false }
        return oriShow
    }
}


// From SimpleModeManager分拆
//class SimpleModeManager-WillDeleteFile中重命名提出来
public struct SimpleModeWillDeleteFile {
    public let objToken: FileListDefine.ObjToken
    public let type: DocsType
    public var isSetManuOffline: Bool = false
    public var thumbUrl: String?
    public var urlEncrypted: String?
}

public protocol SimpleModeObserver: AnyObject {
    func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile], completion: (() -> Void)?)
}


protocol SimpleModeManagerAPI: AnyObject {
    func addObserver(_ target: SimpleModeObserver)
    func removeObserver(_ target: SimpleModeObserver)
}


final class SimpleModeWeakObserver {
    weak var value: SimpleModeObserver?
}


/// 精简模式的开关和配置获取，定时器触发
public final class SimpleModeManager {

    private var observers = [SimpleModeWeakObserver]()
    private var hadRegisterObservers = false
    private var isNeedCleanData = false
    /// 精简模式开关是否开启
    public static var isOn: Bool {
        return DocsConfigManager.LeanMode.isOn
    }

    /// 精简模式只显示多少时间范围内浏览过的数据
    private static var _timeLimit: TimeInterval = 0
    public static var timeLimit: TimeInterval {
        get {
            return _timeLimit > 0 ? _timeLimit : (Date().timeIntervalSince1970 - 24 * 60 * 60)
        }
        set { _timeLimit = newValue }
    }

    private static var simpleModeManager: SimpleModeManager {
        return DocsContainer.shared.resolve(SimpleModeManager.self) ?? SimpleModeManager()
    }

    private let serialQueue: DispatchQueue = DispatchQueue(label: "com.docs.SimpleModeManager", qos: DispatchQoS.utility)

    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogin), name: Notification.Name.Docs.userDidLogin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogout), name: Notification.Name.Docs.userDidLogout, object: nil)
    }

    @objc
    func userDidLogin() {
        DocsLogger.info("userDidLogin", component: LogComponents.simpleMode)
        registerObservers()
        checkIfNeedClearData()
        checkToDeleteManuofflineFilesCache()
    }

    @objc
    func userDidLogout() {
        DocsLogger.info("userDidLogout", component: LogComponents.simpleMode)
        // remove开关值和配置信息
        removeAllObservers()
    }

    private func registerObservers() {
        guard SimpleModeManager.isOn else {
            DocsLogger.info("registerObservers, but not in simple mode", component: LogComponents.simpleMode)
            return
        }

        DocsLogger.info("registerObservers start", component: LogComponents.simpleMode)

        // 手动离线，由列表页触发删除
        if let fileListManuOfflineMgr = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self) {
            self.addObserver(fileListManuOfflineMgr)
        }
        // 下面是各个业务线添加监听，顺序不影响，只要在这个方法添加就行
        if let driveCache = DocsContainer.shared.resolve(DriveCacheServiceBase.self) { //DriveCacheService.shared
            addObserver(driveCache)
        }
        if let wikiStorage = DocsContainer.shared.resolve(SKCommonDependency.self)?.getWikiStorageObserver() {
            addObserver(wikiStorage)
        }
        if let newCacheStorage = DocsContainer.shared.resolve(NewCacheAPI.self) {
            self.addObserver(newCacheStorage)
        }
        if let spaceThumbnailManager = DocsContainer.shared.resolve(SpaceThumbnailManager.self) {
            self.addObserver(spaceThumbnailManager)
        }
        if let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) {
            addObserver(dataCenterAPI.simpleModeObserver)
        }

        hadRegisterObservers = true

    }
    private func removeAllObservers() {
        DocsLogger.info("removeAllObservers", component: LogComponents.simpleMode)
        asyncExcute {[weak self] in
            self?.observers.removeAll()
        }
        hadRegisterObservers = false
    }

    public static func trigerClearActions() {
        guard SimpleModeManager.isOn else { return }
        DocsLogger.info("trigerClearActions", component: LogComponents.simpleMode)
        simpleModeManager.isNeedCleanData = true
        simpleModeManager.checkIfNeedClearData()
    }

    func checkIfNeedClearData() {
        guard
            SimpleModeManager.isOn,
            hadRegisterObservers,
            isNeedCleanData
            else {
                DocsLogger.info("checkIfNeedClearData, not need clear", component: LogComponents.simpleMode)
                return
        }
        DocsLogger.info("checkIfNeedClearData, need clear", component: LogComponents.simpleMode)
        isNeedCleanData = false
        clearAllSmallerOpenTimeData()
    }

    private func checkToDeleteManuofflineFilesCache() {
        guard SimpleModeManager.isOn,
            let fileListManuOfflineMgr = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self) else {
                return
        }
        findObjTokensToDelete(isNeedClear: false) { deletedFiles in
            fileListManuOfflineMgr.deleteFilesInSimpleMode(deletedFiles, completion: nil)
        }
    }
}

extension SimpleModeManager {

    private func clearAllSmallerOpenTimeData() {
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            spaceAssertionFailure("dataCenterAPI nil")
            return
        }
        let deleteBlock: () -> Void = {
            self.findObjTokensToDelete()
        }

        if dataCenterAPI.hadLoadDBForCurrentUser {
            deleteBlock()
            return
        }

        guard let userID = User.current.info?.userID, !userID.isEmpty else {
            DocsLogger.warning("user id is empty")
            return
        }

        dataCenterAPI.forceAsyncLoadDBIfNeeded(userID) { ret in
            guard ret else {
                DocsLogger.error("load db fail")
                return
            }
            deleteBlock()
        }
    }

    private func findObjTokensToDelete(isNeedClear: Bool = true, _ completion: (([SimpleModeWillDeleteFile]) -> Void)? = nil) {
        asyncExcute { [weak self] in
            DocsLogger.info("start to find files to delete in simple mode, isNeedClear:\(isNeedClear)", component: LogComponents.simpleMode)
            var deleteObjTokens = [FileListDefine.ObjToken]()
            var deleteFiles = [SimpleModeWillDeleteFile]()
            // 找出列表页的要清除的数据, 考虑列表页懒加载
            let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
            let allEntries = dataCenterAPI?.getAllSpaceEntries() ?? [:]
            for (objToken, fileEntry) in allEntries {
                var needDelete = false
                if fileEntry.openTime == nil {
                    needDelete = true
                } else if let openTime = fileEntry.openTime, openTime <= SimpleModeManager.timeLimit {
                    needDelete = true
                }

                if needDelete {
                    deleteObjTokens.append(objToken)
                    var fileToDelete = SimpleModeWillDeleteFile(objToken: objToken, type: fileEntry.type)
                    fileToDelete.isSetManuOffline = fileEntry.isSetManuOffline
                    deleteFiles.append(fileToDelete)
                }
            }

            DocsLogger.info("finish to find files to delete in simple mode, file count:\(deleteFiles.count), isNeedClear:\(isNeedClear)", component: LogComponents.simpleMode)
            // 调用各个业务方提供的接口，清除数据
            guard let self = self, isNeedClear else {
                completion?(deleteFiles)
                return
            }
            DocsLogger.info("clear files right now", component: LogComponents.simpleMode)
            DispatchQueue.global().async {
                // 根据情况，看看是否要放到其他业务方都删除了本地数据之后再删除列表页数据
                dataCenterAPI?.deleteSpaceEntriesForSimpleMode(files: deleteFiles)
            }

            self.observers.forEach { (observer) in
                guard let value = observer.value else { return }
                value.deleteFilesInSimpleMode(deleteFiles) {
                    // 统计，都完成了
                }
            }

            NotificationCenter.default.post(name: Notification.Name.Docs.clearDataNoticationInSimpleMode,
                                            object: nil, userInfo: nil)
            completion?(deleteFiles)

        }
    }

    private func asyncExcute(_ block: @escaping () -> Void) {
        serialQueue.async {
            block()
        }
    }
}

extension SimpleModeManager: SimpleModeManagerAPI {
    func addObserver(_ target: SimpleModeObserver) {
        asyncExcute {[weak self] in
            guard let self = self else { return }
            let newObserver = SimpleModeWeakObserver()
            newObserver.value = target
            self.observers.removeAll { (observer) -> Bool in
                if observer.value == nil { return true }
                if let v = observer.value, v === target { return true }
                return false
            }
            self.observers.append(newObserver)
        }
    }

    func removeObserver(_ target: SimpleModeObserver) {
        asyncExcute { [weak self] in
            guard let self = self else { return }
            self.observers.removeAll { (observer) -> Bool in
                if observer.value == nil { return true }
                if let v = observer.value, v === target { return true }
                return false
            }
        }
    }
}
