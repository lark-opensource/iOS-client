//
//  DriveManualOfflineService.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/8/5.
//  
// swiftlint:disable file_length
import Foundation
import SKCommon
import SKFoundation
import SKInfra
import LarkDocsIcon

private let cacheRootURL = SKFilePath.driveCacheDir
// $cacheRootURL/$userID/$cacheConfigFileName
private let cacheConfigFileName = "drive_manual_cache_config.json"

private class DriveManualOfflineFile: NSObject, Codable {

    struct Meta: Codable, Comparable {
        let updateDate: Date
        let size: UInt64
        let name: String
        let type: String
        var version: String?
        var dataVersion: String?

        var fileExtension: String? {
            return SKFilePath.getFileExtension(from: name)
        }

        init(fileInfo: DriveFileInfo) {
            updateDate = Date()
            size = fileInfo.size
            name = fileInfo.name
            type = fileInfo.type
            version = fileInfo.version
            dataVersion = fileInfo.dataVersion
        }

        static func == (lhs: Meta, rhs: Meta) -> Bool {
            return lhs.version == rhs.version &&
            lhs.dataVersion == rhs.dataVersion &&
            lhs.name == rhs.name &&
            lhs.updateDate == rhs.updateDate &&
            lhs.type == rhs.type &&
            lhs.size == rhs.size
        }

        static func < (lhs: Meta, rhs: Meta) -> Bool {
            return lhs.updateDate < rhs.updateDate
        }
    }

    enum Status: String, Codable {
        case updatingFileInfo
        case downloading
        case failed
        case downloaded
        case pending
    }

    let token: String
    /// 用于区分是否曾经下载完成过，若是，则任何操作都不通知UI更新
    var hasDownloaded: Bool
    /// 用于表示是否是本次app启动中新增加的文件
    var isNew: Bool
    var status: Status
    var meta: Meta?
    var retryCount: Int
    var wikiToken: String?
    /// 列表中文档的objToken，wiki类型的objToken为WikiToken
    var listToken: String {
        if let wikiToken {
            return wikiToken
        }
        return token
    }
    var fileType: DriveFileType {
        return DriveFileType(fileExtension: meta?.fileExtension)
    }

    var fileExtension: String? {
        return meta?.fileExtension
    }

    var needUpdate: Bool {
        switch status {
        case .updatingFileInfo:
            return true
        case .downloading:
            return true
        case .failed:
            return true
        case .downloaded:
            guard let meta = meta else {
                return true
            }
            guard DriveCacheService.shared.isDriveFileExist(token: token, dataVersion: meta.dataVersion, fileExtension: meta.fileExtension) else {
                return true
            }
            let current = Date()
            let interval = current.timeIntervalSince(meta.updateDate)
            if interval >= 7 * 24 * 60 * 60 {
                return true
            } else {
                return false
            }
        case .pending:
            return true
        }
    }

    init(token: String, hasDownloaded: Bool, status: Status, meta: Meta?, isNew: Bool = true, wikiToken: String?) {
        self.token = token
        self.hasDownloaded = hasDownloaded
        self.status = status
        self.meta = meta
        self.isNew = isNew
        self.wikiToken = wikiToken
        retryCount = 0
    }
}

class DriveManualOfflineService: NSObject {

    enum DownloadStrategy: Int, Codable {
        case unknown
        case wifiOnly
        case allNetwork
    }

    private struct Config: Codable {
        let offlineTokens: Set<String>
        let offlineFiles: [String: DriveManualOfflineFile]?
        let offlineWikiTokens: [String: String]
    }

    var manualOfflineEnabled: Bool {
        return DriveFeatureGate.manualOfflineEnabled
    }

    static let shared = DriveManualOfflineService()

    let label: String
    private let queue: DispatchQueue
    private var offlineTokens: Set<String>
    private var offlineFiles: [String: DriveManualOfflineFile]
    /// key: objToken value: wikiToken
    private var offlineWikiTokens: [String: String]
    private var downloadingTokens: Set<String>
    private var userID: String
    private var drivePreviewCount: [String: Int]
    private let downloadService: DrivePreloadDownloadService
    private(set) var dataThreadhold: UInt64 = 50 * 1024 * 1024
    private weak var offlineManager: FileManualOfflineManagerAPI?
    private(set) var isReachable: Bool
    private(set) var networkState: ManualOfflineAction.NetState
    private(set) var downloadStrategy: DownloadStrategy
    private let dataCenterAPI: DataCenterAPI

    private override init() {
        label = "Drive.ManualOffline.Shared"
        queue = DispatchQueue(label: label, attributes: [.concurrent])
        offlineTokens = []
        offlineFiles = [:]
        offlineWikiTokens = [:]
        downloadingTokens = []
        offlineManager = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self)
        isReachable = false
        networkState = .unkown
        downloadStrategy = .unknown
        userID = User.current.info?.userID ?? "default"
        drivePreviewCount = [:]
        downloadService = DrivePreloadDownloadService(label: "ManualOffline")
        dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)!

        super.init()
        downloadService.delegate = self
    }

    func reload(userID: String?) {
        self.userID = userID ?? "default"
        offlineManager?.removeObserver(self)
        pendingAllFiles()
        loadConfig()
        offlineManager?.addObserver(self)
    }

    func requestManualOffline(preloadKeys: [DrivePreloadKey]) {
        guard manualOfflineEnabled else { return }
        queue.async(flags: [.barrier]) {
            preloadKeys.forEach {
                self.unsafeRequestManualOffline(preloadKey: $0)
                self.offlineManager?.excuteCallBack(.progressing($0.fileToken, extra: nil))
            }
            self.unsaveSaveConfig()
        }
    }

    func updateManualOffline(preloadKeys: [DrivePreloadKey]) {
        guard manualOfflineEnabled else { return }
        queue.async(flags: [.barrier]) {
            preloadKeys.forEach {
                self.unsafeUpdateManualOffline(preloadKey: $0)
            }
            self.unsaveSaveConfig()
        }
    }

    func cancelManualOffline(preloadKeys: [DrivePreloadKey]) {
        guard manualOfflineEnabled else { return }
        queue.async(flags: [.barrier]) {
            preloadKeys.forEach { self.unsaveCancelManualOffline(preloadKey: $0)}
            self.unsaveSaveConfig()
        }
    }
}

// MARK: - DrivePreloadDelegate
extension DriveManualOfflineService: DrivePreloadDelegate {
    func operation(_ operation: DrivePreloadOperation, updateFileInfo fileInfo: DriveFileInfo) {
        DocsLogger.driveInfo("\(label) --- operation file info update", extraInfo: ["token": DocsTracker.encrypt(id: operation.fileToken)])
        guard manualOfflineEnabled else { return }
        guard operation.preloadSource == .manualOffline else { return }
        queue.async(flags: [.barrier]) {
            let token = operation.fileToken
            guard self.offlineTokens.contains(token) else { return }
            let meta = DriveManualOfflineFile.Meta(fileInfo: fileInfo)
            if let file = self.offlineFiles[token] {
                file.meta = meta
            } else {
                let file = DriveManualOfflineFile(token: token,
                                                  hasDownloaded: false,
                                                  status: .downloading,
                                                  meta: meta,
                                                  wikiToken: operation.wikiToken)
                self.offlineFiles[token] = file
            }
            let extraInfo: [ManualOfflineCallBack.ExtraKey: Any] = [.fileSize: meta.size]
            self.offlineManager?.excuteCallBack(.updateFileInfo(token, extra: extraInfo))
            if self.networkState == .wifi {
                self.unsaveSaveConfig()
                return
            }
            self.unsaveSaveConfig()
        }
    }

    func operation(_ operation: DrivePreloadOperation, failedWithError error: DrivePreloadOperation.PreloadError) {
        guard manualOfflineEnabled else { return }
        guard operation.preloadSource == .manualOffline else { return }
        queue.async(flags: [.barrier]) {
            let token = operation.fileToken
            let preloadKey = DrivePreloadKey(fileToken: operation.fileToken, wikiToken: operation.wikiToken)
            guard let file = self.offlineFiles[token] else {
                DocsLogger.error("\(self.label) --- offlineFiles not found when operation failed with error",
                                 extraInfo: ["token": DocsTracker.encrypt(id: operation.fileToken), "error": error.localizedDescription])
                return
            }
            if let index = self.downloadingTokens.firstIndex(of: token) {
                self.downloadingTokens.remove(at: index)
            }
            switch error {
            case .downloadCancelled:
                DocsLogger.driveInfo("\(self.label) --- download task was cancelled in other place", extraInfo: ["token": DocsTracker.encrypt(id: operation.fileToken), "error": error.localizedDescription])
                file.retryCount -= 1
            case .fileSizeExceedLimit, .fileTypeUnsupport:
                self.offlineManager?.excuteCallBack(.failed(token, error.localizedDescription, extra: nil))
                assertionFailure("Manual Offline should not receive theses kind of error")
                DocsLogger.error("\(self.label) --- Manual Offline should not receive theses kind of error",
                                 extraInfo: ["token": DocsTracker.encrypt(id: operation.fileToken), "error": error.localizedDescription])
                file.status = .failed
                if !file.hasDownloaded {
                    self.dataCenterAPI.updateUIModifier(tokenInfos: [operation.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .fail)])
                }
            case .downloadError, .cacheError, .previewInfoError, .fileInfoError:
                self.offlineManager?.excuteCallBack(.failed(token, error.localizedDescription, extra: nil))
                DocsLogger.driveInfo("\(self.label) --- operation failed with error", extraInfo: ["token": DocsTracker.encrypt(id: operation.fileToken), "error": error.localizedDescription])
                file.status = .failed
                if !file.hasDownloaded {
                    self.dataCenterAPI.updateUIModifier(tokenInfos: [operation.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .fail)])
                }
            case .cancelled:
                DocsLogger.driveInfo("\(self.label) --- operation was cancelled", extraInfo: ["token": DocsTracker.encrypt(id: operation.fileToken), "error": error.localizedDescription])
                file.status = .pending
                if !file.hasDownloaded {
                    self.dataCenterAPI.updateUIModifier(tokenInfos: [operation.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .waiting)])
                }
            case .fileNotFound:
                DocsLogger.driveInfo("\(self.label) --- file deleted", extraInfo: ["token": DocsTracker.encrypt(id: operation.fileToken), "error": error.localizedDescription])
                self.unsaveCancelManualOffline(preloadKey: preloadKey)
                DriveCacheService.shared.deleteDriveFile(token: token, dataVersion: nil)
                self.offlineManager?.excuteCallBack(.canNotCacheFile(token, extra: [.entityDeleted: true, .listToken: operation.listToken]))
                self.dataCenterAPI.updateUIModifier(tokenInfos: [operation.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .none)])
            case .noPermissionOrAudit:
                DocsLogger.driveInfo("\(self.label) --- file permission denied", extraInfo: ["token": DocsTracker.encrypt(id: operation.fileToken), "error": error.localizedDescription])
                self.unsaveCancelManualOffline(preloadKey: preloadKey)
                DriveCacheService.shared.deleteDriveFile(token: token, dataVersion: nil)
                self.offlineManager?.excuteCallBack(.canNotCacheFile(operation.listToken, extra: [.noPermission: true, .listToken: operation.listToken]))
                // 对齐Android，移除列表页入口，而不是updateUIModifier
                // self.dataCenterAPI.updateUIModifier(tokenInfos: [operation.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .none)])
                self.dataCenterAPI.deleteSpaceEntry(token: TokenStruct(token: token))
            }
            self.unsaveSaveConfig()
        }
    }

    func operation(_ operation: DrivePreloadOperation, didFinishedWithResult isSuccess: Bool) {
        DocsLogger.driveInfo("\(label) --- operation finish", extraInfo: ["token": DocsTracker.encrypt(id: operation.fileToken), "result": isSuccess])
        guard manualOfflineEnabled else { return }
        guard operation.preloadSource == .manualOffline else { return }
        queue.async(flags: [.barrier]) {
            let token = operation.fileToken
            guard let file = self.offlineFiles[token] else {
                return
            }
            if let index = self.downloadingTokens.firstIndex(of: token) {
                self.downloadingTokens.remove(at: index)
            }
            guard isSuccess else {
                self.retry(file: file)
                return
            }
            file.hasDownloaded = true
            file.status = .downloaded
            let extraInfo: [ManualOfflineCallBack.ExtraKey: Any] = [.updateTime: Date().timeIntervalSince1970]
            self.offlineManager?.excuteCallBack(.succeed(token, extra: extraInfo))
            self.dataCenterAPI.updateUIModifier(tokenInfos: [operation.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .success)])
            DispatchQueue.main.docAsyncAfter(2, block: {
                self.dataCenterAPI.updateUIModifier(tokenInfos: [operation.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .successOver2s)])
            })
            self.unsaveSaveConfig()
        }
    }
}

extension DriveManualOfflineService: ManualOfflineFileStatusObserver {
    func didReceivedFileOfflineStatusAction(_ action: ManualOfflineAction) {
        guard manualOfflineEnabled else { return }
        let preloadKeys = action.files.compactMap { file in
            if let wikiInfo = file.wikiInfo, wikiInfo.docsType == .file {
                return DrivePreloadKey(fileToken: wikiInfo.objToken, wikiToken: wikiInfo.wikiToken)
            }
            if file.type == .file {
                return DrivePreloadKey(fileToken: file.objToken)
            }
            return nil
        }
        // action 里面有 token 不能直接打进 log
        DocsLogger.driveInfo("\(label) --- received manual offline action", extraInfo: ["event": action.event])
        switch action.event {
        case .add:
            requestManualOffline(preloadKeys: preloadKeys)
        case .remove:
            if let extraInfo = action.extra,
                let isRemove = extraInfo[.entityDeleted] as? Bool,
                isRemove {
                updateManualOffline(preloadKeys: preloadKeys)
                preloadKeys.forEach { // 删除缓存
                    DriveCacheService.shared.deleteDriveFile(token: $0.fileToken, dataVersion: nil)
                }
            }
            cancelManualOffline(preloadKeys: preloadKeys)
        case .update:
            updateManualOffline(preloadKeys: preloadKeys)
        case .refreshData:
            updateManualOffline(preloadKeys: preloadKeys)
        case .download(let strategy):
            switch strategy {
            case .wifiOnly:
                downloadStrategy = .wifiOnly
            case .wwanAndWifi:
                downloadStrategy = .allNetwork
            }
            retryNonOfflineFiles()
        case let .netStateChanged(_, newState, _, isReachable):
            // 中台约定在添加观察者时触发网络状态更新，因此在这里恢复未完成离线的下载操作
            networkState = newState
            self.isReachable = isReachable
            if isReachable {
                resetRetryCount()
                retryNonOfflineFiles()
            } else {
                pendingAllFiles()
            }
        // 和drive无关的值
        case .showDownloadJudgeUI, .showNoStorageUI, .startOpen, .endOpen:
            break
        }
    }
}

// MARK: - Private Helper Functions
extension DriveManualOfflineService {

    private func canRetry(for file: DriveManualOfflineFile) -> (needRetry: Bool, isFailed: Bool) {
        guard offlineTokens.contains(file.token) else {
            // 忽略不在手动离线范围内的token
            return (false, false)
        }
        if file.retryCount >= 3 {
            // 重试达到上限，提示错误
            return (false, true)
        }
        guard let meta = file.meta else { return (true, false) }
        if meta.size < dataThreadhold { return (true, false) }
        if networkState == .wifi { return (true, false) }
        if file.isNew && downloadStrategy == .allNetwork { return (true, false) }
        // 等待WiFi下载
        return (false, false)
    }

    private func retry(file: DriveManualOfflineFile) {
        let (needRetry, isFailed) = canRetry(for: file)
        let preloadKey = DrivePreloadKey(fileToken: file.token, wikiToken: file.wikiToken)
        guard needRetry else {
            if isFailed && !file.hasDownloaded {
                file.status = .failed
                dataCenterAPI.updateUIModifier(tokenInfos: [preloadKey.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .fail)])
            } else if !file.hasDownloaded {
                file.status = .pending
                dataCenterAPI.updateUIModifier(tokenInfos: [preloadKey.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .waiting)])
            }
            return
        }
        DocsLogger.driveInfo("\(label) --- retry offline file for token: \(DocsTracker.encrypt(id: file.token))")
        file.retryCount += 1
        unsafeUpdateManualOffline(preloadKey: preloadKey)
    }

    private func pendingAllFiles() {
        DocsLogger.driveInfo("\(label) --- prepare to pause all requests")
        queue.async(flags: [.barrier]) {
            DocsLogger.driveInfo("\(self.label) --- pending all requests")
            self.downloadingTokens.forEach { (token) in
                DocsLogger.driveInfo("\(self.label) --- pause drive manual offline request", extraInfo: ["token": DocsTracker.encrypt(id: token)])
                self.downloadService.cancel(token: token)
                guard let file = self.offlineFiles[token] else { return }
                file.status = .pending
                if !file.hasDownloaded {
                    DocsLogger.driveInfo("\(self.label) --- prepare to dispatch UI action", extraInfo: ["token": DocsTracker.encrypt(id: token)])
                    self.dataCenterAPI.updateUIModifier(tokenInfos: [file.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .waiting)])
                    DocsLogger.driveInfo("\(self.label) --- finished to dispatch UI action", extraInfo: ["token": DocsTracker.encrypt(id: token)])
                }
            }
            self.downloadingTokens = []
            DocsLogger.driveInfo("\(self.label) --- pending all requests complete")
        }
    }

    private func resetRetryCount() {
        DocsLogger.driveInfo("\(label) --- reset retry count")
        queue.sync(flags: [.barrier]) {
            offlineFiles.forEach { (keyPair) in
                keyPair.value.retryCount = 0
            }
        }
    }

    private func retryNonOfflineFiles() {
        guard manualOfflineEnabled else { return }
        let outdateTokens = queue.sync {
            offlineTokens.filter { token in
                guard let file = offlineFiles[token] else { return true }
                let (needRetry, _) = canRetry(for: file)
                guard needRetry else { return false }
                if file.needUpdate {
                    file.retryCount += 1
                }
                return file.needUpdate
            }
        }
        let preloadKeys: [DrivePreloadKey] = queue.sync {
            Array(outdateTokens).compactMap { token in
                if let file = offlineFiles[token] {
                    return DrivePreloadKey(fileToken: token, wikiToken: file.wikiToken)
                }
                
                if let wikiToken = offlineWikiTokens[token] {
                    return DrivePreloadKey(fileToken: token, wikiToken: wikiToken)
                }
                
                return DrivePreloadKey(fileToken: token)
            }
        }
        updateManualOffline(preloadKeys: preloadKeys)
    }

    private func unsafeRequestManualOffline(preloadKey: DrivePreloadKey) {
        DocsLogger.driveInfo("\(label) --- request offline file for token: \(DocsTracker.encrypt(id: preloadKey.fileToken))")
        let token = preloadKey.fileToken
        if offlineFiles[token] != nil {
            DocsLogger.driveInfo("\(label) --- request offline file which is already offline, update instead.")
            unsafeUpdateManualOffline(preloadKey: preloadKey)
            return
        }
        guard !downloadingTokens.contains(token) else { return }
        offlineTokens.insert(token)
        offlineWikiTokens[token] = preloadKey.wikiToken
        guard isReachable else {
            dataCenterAPI.updateUIModifier(tokenInfos: [preloadKey.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .waiting)])
            return
        }
        downloadingTokens.insert(token)
        let file = DriveManualOfflineFile(token: token,
                                          hasDownloaded: false,
                                          status: .updatingFileInfo,
                                          meta: nil,
                                          wikiToken: preloadKey.wikiToken)
        offlineFiles[token] = file
        downloadService.download(request: DrivePreloadService.Request(token: token, fileType: file.fileType, sizeLimit: .max, source: .manualOffline), wikiToken: preloadKey.wikiToken)
        dataCenterAPI.updateUIModifier(tokenInfos: [preloadKey.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .downloading)])
    }

    private func unsafeUpdateManualOffline(preloadKey: DrivePreloadKey) {
        DocsLogger.driveInfo("\(label) --- update offline file for token: \(DocsTracker.encrypt(id: preloadKey.fileToken))")
        let token = preloadKey.fileToken
        guard let file = offlineFiles[token] else {
            DocsLogger.driveInfo("\(label) --- updating file which is not manual offline yet, offline instead.")
            unsafeRequestManualOffline(preloadKey: preloadKey)
            return
        }
        guard !downloadingTokens.contains(token) else { return }
        downloadingTokens.insert(token)
        if !offlineTokens.contains(token) {
            DocsLogger.driveInfo("\(label) --- offlineTokens not found but offlineFiles found when update manual offline.")
            offlineTokens.insert(token)
            offlineWikiTokens[token] = preloadKey.wikiToken
        }
        file.status = .updatingFileInfo
        downloadService.download(request: DrivePreloadService.Request(token: token, fileType: file.fileType, sizeLimit: .max, source: .manualOffline), wikiToken: preloadKey.wikiToken)
        if !file.hasDownloaded {
            dataCenterAPI.resetManuOfflineStatus(objToken: preloadKey.listToken)
            dataCenterAPI.updateUIModifier(tokenInfos: [preloadKey.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .downloading)])
        }
    }

    private func unsaveCancelManualOffline(preloadKey: DrivePreloadKey) {
        let token = preloadKey.fileToken
        DocsLogger.driveInfo("\(label) --- cancel offline file for token: \(DocsTracker.encrypt(id: token))")
        guard offlineFiles[token] != nil else {
            DocsLogger.driveInfo("\(label) --- cancel manual offline failed, file not set to manual offline yet.")
            return
        }
        //stop ongoing task
        downloadService.cancel(token: token)
        //clean cache
        DriveCacheService.shared.moveOutManualOffline(tokens: [token], complete: {
            DispatchQueue.main.async {
                let userInfo = [DriveCacheService.manualOfflineNotifyKey: [token]]
                NotificationCenter.default.post(name: DriveCacheService.manualOffilineNotify,
                                                object: nil,
                                                userInfo: userInfo)
            }
        })
        //clean data
        if let index = offlineTokens.firstIndex(of: token) {
            offlineTokens.remove(at: index)
            offlineWikiTokens.removeValue(forKey: token)
        } else {
            DocsLogger.driveInfo("\(label) --- offlineTokens not found but offlineFiles found when cancel manual offline.")
        }
        offlineFiles[token] = nil
        if let index = downloadingTokens.firstIndex(of: token) {
            downloadingTokens.remove(at: index)
        }
        self.dataCenterAPI.updateUIModifier(tokenInfos: [preloadKey.listToken: SyncStatus(upSyncStatus: .none, downloadStatus: .none)])
    }

    private func loadConfig() {
        queue.async(flags: [.barrier]) {
            self.unsaveLoadConfig()
        }
    }

    private func unsaveLoadConfig() {
        let configFileURL = cacheRootURL.appendingRelativePath(userID).appendingRelativePath(cacheConfigFileName)
        if let data = try? Data.read(from: configFileURL),
            let cacheConfig = try? JSONDecoder().decode(Config.self, from: data) {
            DocsLogger.driveInfo("\(label) --- load drive manual offline config")
            offlineTokens = cacheConfig.offlineTokens
            offlineWikiTokens = cacheConfig.offlineWikiTokens
            if let files = cacheConfig.offlineFiles {
                offlineFiles = files
                offlineFiles.forEach { (keyPair) in
                    let (token, file) = keyPair
                    file.isNew = false
                    if !DriveCacheService.shared.isDriveFileExist(token: token, dataVersion: file.meta?.dataVersion, fileExtension: file.fileExtension) {
                        file.hasDownloaded = false
                        file.status = .pending
                    }
                }
            } else {
                offlineTokens.forEach { (token) in
                    var wikiToken: String?
                    if let _wikiToken = offlineWikiTokens[token] {
                        wikiToken = _wikiToken
                    }
                    offlineFiles[token] = DriveManualOfflineFile(token: token,
                                                                 hasDownloaded: false,
                                                                 status: .pending,
                                                                 meta: nil,
                                                                 isNew: false,
                                                                 wikiToken: wikiToken)
                }
            }

            var fileStatus: [FileListDefine.ObjToken: SyncStatus] = [:]
            offlineFiles.forEach { (keyPair) in
                let (token, file) = keyPair
                let preloadKey = DrivePreloadKey(fileToken: token, wikiToken: file.wikiToken)
                switch file.status {
                case .updatingFileInfo, .downloading, .failed, .pending:
                    fileStatus[preloadKey.listToken] = SyncStatus(upSyncStatus: .none, downloadStatus: .waiting)
                    file.status = .pending
                case .downloaded:
                    fileStatus[preloadKey.listToken] = SyncStatus(upSyncStatus: .none, downloadStatus: .successOver2s)
                }
            }
            dataCenterAPI.updateUIModifier(tokenInfos: fileStatus)
        } else {
            offlineTokens = []
            offlineFiles = [:]
            downloadingTokens = []
            DocsLogger.driveInfo("\(label) --- failed to load drive manual offline config")
        }
    }

    private func unsaveSaveConfig() {
        let config = Config(offlineTokens: offlineTokens, offlineFiles: offlineFiles, offlineWikiTokens: offlineWikiTokens)
        let configFileURL = cacheRootURL.appendingRelativePath(userID).appendingRelativePath(cacheConfigFileName)
        let encoder = JSONEncoder()
        guard let configData = try? encoder.encode(config) else {
            assertionFailure("\(label) --- Failed to encode drive manual offline config")
            DocsLogger.error("\(label) --- Failed to encode drive manual offline config")
            return
        }
        guard configFileURL.writeFile(with: configData, mode: .over) else {
            DocsLogger.error("\(label) --- Failed to save drive manual offline config")
            try? configFileURL.removeItem()
            return
        }
    }
}
// swiftlint:enable file_length
/// 兼容Wiki
extension DriveManualOfflineService {
    struct DrivePreloadKey {
        /// Drive文件真实的Token
        let fileToken: String
        /// Wiki Drive携带WikiToken
        let wikiToken: String?
        /// wiki在列表页的ObjToken就是WikiToken，同步列表正确的离线状态
        var listToken: String {
            if let wikiToken {
                return wikiToken
            }
            return fileToken
        }
        
        init(fileToken: String, wikiToken: String? = nil) {
            self.fileToken = fileToken
            self.wikiToken = wikiToken
        }
    }
}
