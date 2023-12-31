//
//  DrivePreloadService.swift
//  SpaceKit
//
//  Created by Wenjian Wu on 2019/3/27.
//  

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface
import LarkDocsIcon

let drivePreloadConfigFilePath = SKFilePath.driveLibraryDir.appendingRelativePath("DrivePreloadConfig.json")

struct DriveThumbPreloadConfig {
    static func shouldDownloadThumb(source: DrivePreloadSource, fileSize: UInt64, fileType: String) -> Bool {
        guard source != .manualOffline else {
            DocsLogger.driveInfo("Drive.Preload.Download--- manualOffline not download thumb")
            return false
        }
        guard fileSize > 0 else {
            DocsLogger.driveInfo("Drive.Preload.Download--- invalid file size 0")
            return false
        }
        guard fileSize < DriveFeatureGate.maxFileSize(for: fileType) else {
            DocsLogger.driveInfo("Drive.Preload.Download--- invalid file size for settings")
            return false
        }
        return true
    }
}

extension DrivePreloadSource {
    var priority: DriveDownloadPriority {
        switch self {
        case .manualOffline:
            return .manualOffline
        default:
            return .preload
        }
    }
}

class DrivePreloadService: DriveMultipDelegates {

    struct Request {
        let token: String
        let fileType: DriveFileType
        let sizeLimit: UInt64
        let source: DrivePreloadSource
    }


    private struct Counter {
        var recentCount = 0
        var pinCount = 0
        var favoriteCount = 0
        var manualOfflineCount = 0
        var config: DrivePreloadConfig

        subscript(source: DrivePreloadSource) -> Int {
            get {
                switch source {
                case .recent:
                    return recentCount
                case .pin:
                    return pinCount
                case .favorite:
                    return favoriteCount
                case .manualOffline:
                    return manualOfflineCount
                }
            }
            set(newValue) {
                switch source {
                case .recent:
                    recentCount = newValue
                case .pin:
                    pinCount = newValue
                case .favorite:
                    favoriteCount = newValue
                case .manualOffline:
                    manualOfflineCount = newValue
                }
            }
        }

        init(config: DrivePreloadConfig) {
            self.config = config
        }

        func canPrefetch(from source: DrivePreloadSource) -> Bool {
            return self[source] < config[source]
        }

        mutating func prefetch(from source: DrivePreloadSource) {
            self[source] += 1
        }
    }

    static let shared = DrivePreloadService()
    private let preloadQueue: DispatchQueue
    private let downloadService: DrivePreloadDownloadService
    private var counter: Counter
    /// 预加载候补队列，当预加载的文件不符合特定条件(无权限、被审核、大小太大)会从候补队列取出下一个文件进行预加载
    private var requestQueues: [DrivePreloadSource: [Request]]
    /// 已经处理过的token，保证重复对同一个文件进行预加载不会影响预加载的计数
    private var preloadedTokens: Set<String>
    private(set) var allowPrefetchUsingCellular: Bool

    var sizeLimit: UInt64 {
        return counter.config.sizeLimit
    }

    var networkAvailableForPreload: Bool {
        // 检查是否允许使用流量预加载
        if !allowPrefetchUsingCellular,
            DocsNetStateMonitor.shared.accessType.isWwan() {
            return false
        }
        return true
    }

    private override init() {
        preloadQueue = DispatchQueue(label: "Drive.Preload.Shared", qos: .default)
        let config = DriveFeatureGate.defaultPreloadConfig
        downloadService = DrivePreloadDownloadService(label: "manager.shared")
        counter = Counter(config: config)
        requestQueues = [:]
        preloadedTokens = []
        allowPrefetchUsingCellular = false //仅 WiFi
        super.init()
        downloadService.delegate = self
        loadConfig()
    }

    // MARK: - 预加载配置
    private func saveConfig() {
        let config = counter.config
        let encoder = JSONEncoder()
        guard let configData = try? encoder.encode(config) else {
            assertionFailure("Drive.PreloadService.shared---Failed to encode prefetch config")
            DocsLogger.error("Drive.PreloadService.shared---Failed to encode prefetch config")
            return
        }
        guard drivePreloadConfigFilePath.writeFile(with: configData, mode: .over) else {
            assertionFailure("Drive.PreloadService.shared---Failed to write prefetch config data to file.")
            DocsLogger.error("Drive.PreloadService.shared---Failed to write prefetch config data to file.")
            return
        }
    }

    private func loadConfig() {
        let decoder = JSONDecoder()
        guard let data = try? Data.read(from: drivePreloadConfigFilePath),
            let config = try? decoder.decode(DrivePreloadConfig.self, from: data) else {
                DocsLogger.driveInfo("Drive.PreloadService.shared---Failed to restore previous saved config.")
                return
        }
        counter.config = config
        DocsLogger.driveInfo("Drive.PreloadService.shared---preload config Loaded.")
    }

    func update(config: DrivePreloadConfig) {
        counter.config = config
        DocsLogger.driveInfo("Drive.PreloadService.shared---Preload config updated.")
        saveConfig()
    }

    // MARK: - 预加载接口

    /// 批量预加载接口
    ///
    /// - Parameters:
    ///   - files: drive 文件 token 和文件大小
    ///   - source: 预加载文件来源
    func handle(files: [(token: String, fileSize: UInt64?, fileType: DriveFileType)], source: DrivePreloadSource) {
        DocsLogger.debug("Drive.PreloadService.shared --- handling preload files, count: \(files.count)")
        // Drive 是否启用
        guard DriveFeatureGate.driveEnabled else {
            return
        }
        preloadQueue.async {
            for file in files {
                self.handle(token: file.token, fileSize: file.fileSize, fileType: file.fileType, source: source)
            }
        }
    }

    /// 单独预加载文件接口
    ///
    /// - Parameters:
    ///   - token: drive 文件 token
    ///   - fileSize: 文件大小，可为空
    ///   - source: 预加载文件来源
    /// - Returns: 是否进行预加载
    @discardableResult
    private func handle(token: String, fileSize: UInt64?, fileType: DriveFileType, source: DrivePreloadSource) -> Bool {
        let request = Request(token: token, fileType: fileType, sizeLimit: sizeLimit, source: source)
        // 无效的预加载请求不会被预加载或添加到预加载候补队列
        guard isValidPreloadRequest(request, fileSize: fileSize, fileType: fileType) else {
            // 重复的token或者文件过大
            DocsLogger.warning("Drive.PreloadService.shared --- invalid preload request, duplicated token or file oversize.")
            return false
        }

        let canPreloadNow = canPreload(token: token,
                                       fileType: fileType,
                                       source: source)
        if canPreloadNow {
            preloadedTokens.insert(token)
            counter.prefetch(from: source)
            guard networkAvailableForPreload else {
                // 因网络原因无法预加载时，依然需要进行计数避免联网后又触发预加载
                DocsLogger.warning("Drive.PreloadService.shared --- Network setting not allow to preload.", extraInfo: ["token": DocsTracker.encrypt(id: token)])
                return false
            }
            downloadService.download(request: request)
        } else {
            // 添加到候补队列
            if requestQueues[source] == nil {
                requestQueues[source] = []
            }
            guard let count = requestQueues[source]?.count else {
                DocsLogger.error("Drive.PreloadService.shared --- error getting request queue count for type: \(source)")
                return false
            }
            guard count < counter.config[source] * 3 else {
                DocsLogger.warning("Drive.PreloadService.shared --- preload queue is full for type: \(source)")
                return false
            }
            DocsLogger.driveInfo("Drive.PreloadService.Shared --- preload request add to waiting queue", extraInfo: ["token": DocsTracker.encrypt(id: token)])
            preloadedTokens.insert(token)
            requestQueues[source]?.append(request)

        }
        return canPreloadNow
    }


    /// 判断预加载请求是否有效
    /// - Note: 已经处理过的token或者文件过大会被视为无效
    /// - Parameters:
    ///   - request: 预加载请求
    ///   - fileSize: 文件大小
    /// - Returns: 请求是否有效
    private func isValidPreloadRequest(_ request: Request, fileSize: UInt64?, fileType: DriveFileType) -> Bool {
        // 过滤已经处理过的token
        if preloadedTokens.contains(request.token) { return false }
        // 过滤大小过大的文件
        guard let fileSize = fileSize else {
            return true
        }

        if fileSize > sizeLimit && !DriveThumbPreloadConfig.shouldDownloadThumb(source: request.source, fileSize: fileSize, fileType: fileType.rawValue) {
            return false
        }

        return true
    }

    /// 判断预加载能否立即进行
    /// - Note: 这里不会考虑文件大小的限制
    /// - Parameters:
    ///   - token: drive 文件 token
    ///   - fileSize: 文件大小
    ///   - source: 预加载文件来源
    /// - Returns: 是否可以进行预加载
    private func canPreload(token: String, fileType: DriveFileType, source: DrivePreloadSource) -> Bool {
        return counter.canPrefetch(from: source)
    }

    /// 预加载候补队列中的下一个文件
    private func preloadNextInQueue(for source: DrivePreloadSource) {
        preloadQueue.async {
            self.counter[source] -= 1
            guard let request = self.requestQueues[source]?.first else {
                DocsLogger.warning("Drive.PreloadService.Shared --- Failed to get Preload Request with index")
                return
            }
            self.requestQueues[source]?.remove(at: 0)
            self.preloadedTokens.remove(request.token)
            self.handle(token: request.token,
                        fileSize: nil,
                        fileType: request.fileType,
                        source: source)
        }
    }
}

extension DrivePreloadService: DrivePreloadDelegate {
    func operation(_ operation: DrivePreloadOperation, updateFileInfo fileInfo: DriveFileInfo) {
        invoke { (delegate: DrivePreloadDelegate) in
            delegate.operation(operation, updateFileInfo: fileInfo)
        }
    }

    func operation(_ operation: DrivePreloadOperation, failedWithError error: DrivePreloadOperation.PreloadError) {
        // 需要顺延预加载的错误类型
        switch error {
        case .fileSizeExceedLimit,
             .fileTypeUnsupport,
             .noPermissionOrAudit:
            let source = operation.preloadRequest.source
            self.preloadNextInQueue(for: source)
        default:
            break
        }
        invoke { (delegate: DrivePreloadDelegate) in
            delegate.operation(operation, failedWithError: error)
        }
    }

    func operation(_ operation: DrivePreloadOperation, didFinishedWithResult isSuccess: Bool) {
        invoke { (delegate: DrivePreloadDelegate) in
            delegate.operation(operation, didFinishedWithResult: isSuccess)
        }
    }
}
extension DrivePreloadService: DrivePreloadServiceBase {

}
