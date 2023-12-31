//
//  MunualOfflineManager.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/8/12.
//  

import Foundation
import RxSwift
import SKCommon
import SKFoundation
import SKInfra

extension FileManualOfflineManagerAPI {
    func removeFromOffline(by file: ManualOfflineFile) {
        removeFromOffline(by: file, extra: nil)
    }
}

fileprivate final class WeakObserver {
    weak var value: ManualOfflineFileStatusObserver?
}

final class FileListManualOfflineManager: FileManualOfflineManagerAPI {

    private static let serialQueue: DispatchQueue = DispatchQueue(label: "com.docs.FileListManualOfflineManager", qos: DispatchQoS.utility)
    fileprivate var observers = [WeakObserver]()
    var curNetState: ManualOfflineAction.NetState = .unkown
    var curIsNetReachable = false
    var isFirstMonitorNet = true

    private let disposeBag = DisposeBag()

    init() {
        guard DocsConfigManager.isShowOffline else { return }

        DocsNetStateMonitor.shared.addObserver(self) {(networkType, isReachable) in
            // 下面这个block，在App处于后台，网络状态变化时，发生过卡死（5s），被watchdog 干掉过，所以直接async 到 serialQueue 中
            FileListManualOfflineManager.serialQueue.async {  [weak self] in
                guard let self = self else { return }
                var newState: ManualOfflineAction.NetState = networkType.isWifi() ? .wifi : .wwan
                if !isReachable {
                    newState = .unkown
                }
                
                if !self.isFirstMonitorNet {
                    DocsLogger.info("\(self) notify \(self.observers) net state changed", component: LogComponents.manuOffline)
                    self.notifyNetState(to: self.observers, newState: newState, isReachable: isReachable)
                }
                
                self.isFirstMonitorNet = false
                self.curNetState = newState
                self.curIsNetReachable = isReachable
            }
        }
    }

    fileprivate func notifyNetState(
        to targetObservers: [WeakObserver],
        newState: ManualOfflineAction.NetState,
        isReachable: Bool) {

        guard !targetObservers.isEmpty else { return }
        DispatchQueue.dataQueueAsyn {

            // 只发送还没有同步失败的
            var unSynFiles = [ManualOfflineFile]()
            /*
             如果列表页正在通过reswift流程去修改state，此时，网络状态变化，走到这里，偶现多线程访问state，导致crash;
             */
            let manualOfflineTokens = SKDataManager.shared.manualOfflineTokens.compactMap { $0.token }
            let files = SKDataManager.shared.getFileEntries(by: manualOfflineTokens)
            files.forEach({ [weak self] (file) in
                if file.syncStatus.downloadStatus == .fail
                    || file.syncStatus.downloadStatus == .waiting {
                    let moFile = ManualOfflineFile(objToken: file.objToken, type: file.type)
                    unSynFiles.append(moFile)
                    self?.preloadImage(of: file.objToken)
                }
            })
            let netChangedEvent = ManualOfflineAction.Event.netStateChanged(self.curNetState, newState, self.curIsNetReachable, isReachable)
            let action = ManualOfflineAction(event: netChangedEvent,
                                             files: unSynFiles,
                                             extra: nil)
            FileListManualOfflineManager.serialQueue.async { [weak self] in
                self?.notify(targetObservers, action: action)
            }
        }
    }

    fileprivate func addFilesAgainAfterSimpleModeClosed(to targetObservers: [WeakObserver]) {

        guard !targetObservers.isEmpty, !SimpleModeManager.isOn else { return }
        DispatchQueue.dataQueueAsyn {

            // 只发送标记成为手动离线，但是没有修改过离线状态的
            var unSynFiles = [ManualOfflineFile]()
            /*
             如果列表页正在通过reswift流程去修改state，此时，网络状态变化，走到这里，偶现多线程访问state，导致crash;
             */
            let allFileEntries = SKDataManager.shared.getAllSpaceEntries()
            allFileEntries.forEach({ [weak self] (objToken, file) in
                if file.isSetManuOffline
                    && file.hadShownManuStatus == false
                    && file.syncStatus.downloadStatus == . none {
                    let moFile = ManualOfflineFile(objToken: file.objToken, type: file.type)
                    unSynFiles.append(moFile)
                    self?.preloadImage(of: file.objToken)
                }
            })
            let action = ManualOfflineAction(event: .add,
                                             files: unSynFiles,
                                             extra: nil)
            FileListManualOfflineManager.serialQueue.async { [weak self] in
                self?.notify(targetObservers, action: action)
            }
        }
    }

    /// 注册监听者，精简模式下，注册无效
    func addObserver(_ target: ManualOfflineFileStatusObserver) {
        guard DocsConfigManager.isShowOffline else { return }
        DocsContainer.shared.resolve(ListConfigAPI.self)?.excuteWhenSpaceAppearIfNeeded(needAdd: true, block: {
            FileListManualOfflineManager.serialQueue.async { [weak self] in
                self?.innerAddObserver(target)
            }
        })
    }

    private func innerAddObserver(_ target: ManualOfflineFileStatusObserver) {
        FileListManualOfflineManager.serialQueue.async { [weak self] in
            guard let self = self else { return }
            DocsLogger.info("\(self) start addObserver: \(target) to \(self.observers)", component: LogComponents.manuOffline)
            self.observers.removeAll { (observer) -> Bool in
                return observer.value == nil
            }
            DocsLogger.info("finished to clear nil observer", component: LogComponents.manuOffline)
            /*
             为了防止在遍历过程中，value(weak)指向的对象被释放了，导致野指针crash, 怀疑跟 “===” 的实现有关系
             */
            let containsObserver = self.observers.contains(where: { (observer) -> Bool in
                if let obj = observer.value {
                    return obj === target
                } else {
                    return false
                }})
            guard !containsObserver else {
                return
            }
            DocsLogger.info("finished to judge not repeat addObserver", component: LogComponents.manuOffline)

            let weakObser = WeakObserver()
            weakObser.value = target
            self.observers.append(weakObser)

            self.notifyNetState(to: [weakObser],
                                newState: self.curNetState,
                                isReachable: self.curIsNetReachable)
            self.addFilesAgainAfterSimpleModeClosed(to: [weakObser])
        }
    }

    func removeObserver(_ target: ManualOfflineFileStatusObserver) {
        FileListManualOfflineManager.serialQueue.async {
            self.observers.removeAll { (observer) -> Bool in
                return observer.value === target || observer.value == nil // 顺便把被释放的也删除了
            }
        }
    }

    func excuteCallBack(_ callBack: ManualOfflineCallBack) {
        FileListManualOfflineManager.serialQueue.async { [weak self] in

            switch callBack {
            case .succeed: ()
            case .failed: ()
            case .progressing: ()
            case let .updateFileInfo(objToken, extra):
                if let extraLo = extra,
                    let fileSize = extraLo[.fileSize] as? UInt64 {
                    // 告诉列表页这个文件的大小
                    SKDataManager.shared.updateFileSize(objToken: objToken, fileSize: fileSize)
                    DocsLogger.info("excuteCallBack: updateFileInfo ", component: LogComponents.manuOffline)
                }

            case let .judgeDownload(objToken, extra: extra):
                if let extraLo = extra,
                    let fileSize = extraLo[.fileSize] as? UInt64,
                    let self = self {
                    let file = ManualOfflineFile(objToken: objToken, type: .file)
                    let action = ManualOfflineAction(event: .showDownloadJudgeUI(fileSize), files: [file], extra: extraLo)
                    self.notifyObserversFileStatusChanged(action: action)
                    // 告诉列表页这个文件的大小
                    SKDataManager.shared.updateFileSize(objToken: objToken, fileSize: fileSize)
                    DocsLogger.info("excuteCallBack: judgeDownload ", component: LogComponents.manuOffline)

                }
            case let .noStorage(objToken, extra: extra):
                guard let self = self else { return }

                let file = ManualOfflineFile(objToken: objToken, type: .file)
                let action = ManualOfflineAction(event: .showNoStorageUI, files: [file], extra: extra)
                self.notifyObserversFileStatusChanged(action: action)

                // 告诉业务端，取消缓存刚才新增的那个文件
                self.removeFromOffline(by: file)
                DocsLogger.info("excuteCallBack: noStorage ", component: LogComponents.manuOffline)

            case let .canNotCacheFile(objToken, extra: extra):
                guard extra != nil,
                    //                    let entityDeleted = extraLo[.entityDeleted] as? Bool,
                    //                    let noPermission = extraLo[.noPermission] as? Bool,
                    let self = self
                    else {
                        DocsLogger.info("excuteCallBack: canNotCacheFile, failed with extra == nil", component: LogComponents.manuOffline)
                        return
                }
                // 重置列表页数据
                var listToken = objToken
                if let token = extra?[.listToken] as? String {
                    listToken = token
                }
                SKDataManager.shared.resetManualOfflineTag(objToken: listToken, isSetManuOffline: false)

                /// 通知业务端一声，移除缓存
                let file = ManualOfflineFile(objToken: objToken, type: .file)
                self.removeFromOffline(by: file)
                DocsLogger.info("excuteCallBack: canNotCacheFile ", component: LogComponents.manuOffline)
            }
        }
    }

    private func notifyObserversFileStatusChanged(action: ManualOfflineAction) {
        FileListManualOfflineManager.serialQueue.async { [weak self] in
            guard let self = self else { return }
            self.notify(self.observers, action: action)
        }
    }

    private func notify(_ targetObservers: [WeakObserver], action: ManualOfflineAction) {

        FileListManualOfflineManager.serialQueue.async {
            DocsLogger.info("notify action:\(action.event) to observers \(targetObservers), count=\(action.files.count)", component: LogComponents.manuOffline)
            targetObservers.forEach({ (weakObsever) in
                guard let obser = weakObsever.value else { return }
                obser.didReceivedFileOfflineStatusAction(action)
            })
        }
    }

    func addToOffline(_ file: ManualOfflineFile) {
        FileListManualOfflineManager.serialQueue.async {
            DocsLogger.info("add file to offline, observers count:\(self.observers.count) ", component: LogComponents.manuOffline)
        }
        preloadImage(of: file.objToken)

        checkIfNeedAddPopViewManagerToObserver(for: file)
        let action = ManualOfflineAction(event: .add, files: [file], extra: nil)
        notifyObserversFileStatusChanged(action: action)
    }

    func updateOffline(_ files: [ManualOfflineFile]) {
        guard !files.isEmpty else {
            return
        }
        let action = ManualOfflineAction(event: .update, files: files, extra: nil)
        notifyObserversFileStatusChanged(action: action)
    }

    func refreshOfflineData(of file: ManualOfflineFile) {
        let action = ManualOfflineAction(event: .refreshData, files: [file], extra: nil)
        notifyObserversFileStatusChanged(action: action)
    }

    func removeFromOffline(by file: ManualOfflineFile, extra: [ManualOfflineCallBack.ExtraKey: Any]? ) {
        let action = ManualOfflineAction(event: .remove, files: [file], extra: extra)
        notifyObserversFileStatusChanged(action: action)
    }
    func removeFromOffline(files: [ManualOfflineFile], extra: [ManualOfflineCallBack.ExtraKey: Any]? = nil) {
         let action = ManualOfflineAction(event: .remove, files: files, extra: extra)
         notifyObserversFileStatusChanged(action: action)
     }

    func startOpen(_ file: ManualOfflineFile) {
        let action = ManualOfflineAction(event: .startOpen, files: [file], extra: nil)
        notifyObserversFileStatusChanged(action: action)
    }

    func endOpen(_ file: ManualOfflineFile) {
        let action = ManualOfflineAction(event: .endOpen, files: [file], extra: nil)
        notifyObserversFileStatusChanged(action: action)
    }

    /// 用户退出登录的时候，需要清空观察者和文件，或者切换key
    func clear() {
        FileListManualOfflineManager.serialQueue.async { [weak self] in
            guard let self = self else { return }
            DocsLogger.info("FileListManualOfflineManager clear staff", component: LogComponents.manuOffline)
            self.observers.removeAll()
        }
        self.isFirstMonitorNet = true
    }

    func download(_ file: ManualOfflineFile, use strategy: ManualOfflineAction.DownloadStrategy) {
        let action = ManualOfflineAction(event: .download(strategy), files: [file], extra: nil)
        notifyObserversFileStatusChanged(action: action)
    }

    func checkIfNeedAddPopViewManagerToObserver(for file: ManualOfflineFile) {
        guard
            file.type == .file,
            let mgr = DocsContainer.shared.resolve(PopViewManagerProtocol.self),
            !mgr.hadShownDownloadJudge
            else {
                return
        }

        addObserver(mgr)
    }

    func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile], completion: (() -> Void)?) {
        DocsLogger.info("FileListManualOfflineManager start to clear data in simple mode", component: LogComponents.simpleMode)

        var offlineFiles = [ManualOfflineFile]()
        for file in files where file.isSetManuOffline {
            offlineFiles.append(ManualOfflineFile(objToken: file.objToken, type: file.type))
        }
        removeFromOffline(files: offlineFiles)
        completion?()
    }
}

// MARK: - 缓存网格视图的图片，这个需求实在太秀了
/// 产品需求：在文档被添加到手动离线文档列表的时候，后台去下载网格视图的缩略图，各种网络切换的时候也要重新下载之前没有下好的
extension FileListManualOfflineManager {
    private func preloadImage(of objToken: FileListDefine.ObjToken) {
        guard let file = SKDataManager.shared.spaceEntry(objToken: objToken),
            let url = file.thumbnailURL else {
            return
        }
        let extraInfo = file.thumbExtraInfo
        let thumbnailURL = URL(string: url)
        guard let thumbnailInfo = SpaceThumbnailInfo(unencryptURL: thumbnailURL, extraInfo: extraInfo) else {
            return
        }
        let thumbnailManager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)
        let thumbnailRequest = SpaceThumbnailManager.Request(token: objToken,
                                                             info: thumbnailInfo,
                                                             source: .spaceList,
                                                             fileType: file.type,
                                                             placeholderImage: nil,
                                                             failureImage: nil, processer: SpaceListIconProcesser())
        thumbnailManager?.getThumbnail(request: thumbnailRequest).subscribe().disposed(by: disposeBag)
    }
}
