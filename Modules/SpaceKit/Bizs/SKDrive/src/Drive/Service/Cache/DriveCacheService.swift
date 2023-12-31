//
//  DriveCacheService.swift
//  SKECM
//
//  Created by Weston Wu on 2020/8/27.
// swiftlint:disable file_length

import Foundation
import SKFoundation
import SKCommon
import RxSwift
import RxRelay
import LarkCache

// MARK: SpaceEntry + fileExtension
extension SpaceEntry {
    var fileExtension: String? {
        return SKFilePath.getFileExtension(from: name)
    }
}

// MARK: DriveFileMeta + fileExtension
extension DriveFileMeta {
    var fileExtension: String? {
        return SKFilePath.getFileExtension(from: name)
    }
}

class DriveCacheService {
    typealias Record = DriveCache.Record
    typealias Node = DriveCache.Node
    typealias RecordFilter = (Record) -> Bool

    /// 缓存请求来源
    ///
    /// - manual: 手动缓存
    /// - history: 历史记录缓存
    /// - standard: 正常预览的文件缓存
    /// - docsImage: 文档内的图片缓存
    /// - tmp: 临时文件缓存（目前暂未用到）
    /// - thirdParty: 外部传入的缓存文件
    enum Source {
        case manual
        case history
        case standard
        case docsManual
        case docsImage
        case tmp
        case thirdParty
        fileprivate var allowWhenDriveDisabled: Bool {
                    switch self {
                    case .docsManual, .docsImage, .thirdParty:
                        return true
                    case .manual, .history, .standard, .tmp:
                        return false
                    }
                }
    }

    enum CacheType: String, Codable, Equatable {
        // 永久缓存
        case persistent
        // 临时缓存
        case transient
    }

    enum CacheError: LocalizedError {
        /// 无法确定 version，调用方未提供且无法找到 token 默认的 version
        case versionNotProvided
        /// token 在缓存中没有任何关联的记录
        case recordsNotFound
        /// 没有找到满足过滤条件的记录，如 version、fileExtension 不匹配
        case noValidRecordFound
        /// 无法确定记录存放的缓存类型，需要检查save方法中是否没有调用didSave方法
        case determineCacheFailed(record: Record)
        /// FG 关闭导致失败
        case driveDisabledByFG
        /// data写入文件失败
        case writeDataFailed
        /// 创建table失败
        case createTableFailed

        var errorDescription: String? {
            switch self {
            case .versionNotProvided:
                return "not valid version provided or found in tokenVersionMap"
            case .recordsNotFound:
                return "not records found for token"
            case .noValidRecordFound:
                return "not valid record found for specified filter"
            case .determineCacheFailed:
                return "unable to determine cache for record"
            case .driveDisabledByFG:
                return "drive disabled by FG"
            case .writeDataFailed:
                return "write data to file failed"
            case .createTableFailed:
                return "create db table failed"
            }
        }
    }
    static let manualOffilineNotify = NSNotification.Name("DriveCacheService.manualOffline.notify")
    static let manualOfflineNotifyKey = "DriveCacheService.manualOffline.notify.tokens"

    static let shared = DriveCacheService(name: "drive.cache.service")
    // 快照文件路径
    static let snapshotFileURL = cacheConfigURL.appendingRelativePath("cache-snapshot.json")

    /// 不自动清理的永久缓存，目前只有手动离线的文件
    private var innerPersistent: DriveCache?
    private var persistentCache: DriveCache {
        guard let cache = innerPersistent else {
            let cache = DriveCache.createPersistentCache()
            innerPersistent = cache
            return cache
        }
        return cache
    }
    /// 自动清理的临时缓存，除手动离线外的其他文件
    private var innerTransient: DriveCache?
    private var transientCache: DriveCache {
        guard let cache = innerTransient else {
            let cache = DriveCache.createTransientCache()
            innerTransient = cache
            return cache
        }
        return cache
    }

    private let disposeBag = DisposeBag()
    private let cacheQueue: DispatchQueue
    private let metaStorage: DriveFileMetaStorage
    private init(name: String) {
        cacheQueue = DispatchQueue(label: name, qos: .default)
        metaStorage = DriveFileMetaDB()
        setupPath()
    }
}

// MARK: - Path Related Operations
extension DriveCacheService {

    // 存放配置用文件夹
    private static let cacheConfigURL = SKFilePath.driveLibraryDir.appendingRelativePath("cache")

    // 临时文件用文件夹
    private static let cacheTmpURL = SKFilePath.driveCacheDir.appendingRelativePath("cache")

    // 下载中临时文件夹
    static let downloadCacheURL = cacheTmpURL.appendingRelativePath("downloading")

    /// 本地预览压缩文件解压目录
    static let archiveTmpURL = cacheTmpURL.appendingRelativePath("archive")
    /// 第三方打开的临时文件夹
    private static let otherTmpURL = cacheTmpURL.appendingRelativePath("other")
    
    private static var cacheTmpURLs: [SKFilePath] {
        [downloadCacheURL, otherTmpURL, archiveTmpURL]
    }

    private func setupPath() {
        Self.cacheConfigURL.createDirectoryIfNeeded()
        Self.cacheTmpURL.createDirectoryIfNeeded()
        Self.downloadCacheURL.createDirectoryIfNeeded()
        Self.otherTmpURL.createDirectoryIfNeeded()
        Self.archiveTmpURL.createDirectoryIfNeeded()
    }

    private func cleanUpTmpURLs() {
        DispatchQueue.global().async {
            Self.cacheTmpURLs.forEach { path in
                try? path.cleanDir()
            }
            DocsLogger.driveInfo("drive.file.cache --- Clean up tmp caches completed.")
        }
    }

    private func generateFileName(fileToken: String, dataVersion: String, type: String) -> String {
        return "\(DocsTracker.encrypt(id: fileToken))_\(dataVersion).\(type)"
    }

    // origin/preview + encrypt_token + dataVersion
    func driveFileCacheName(cacheType: DriveCacheType, fileToken: String, dataVersion: String, fileExtension: String) -> String {
        return "\(cacheType.identifier)_" + generateFileName(fileToken: fileToken, dataVersion: dataVersion, type: fileExtension)
    }

    func driveFileDownloadURL(cacheType: DriveCacheType, fileToken: String, dataVersion: String, fileExtension: String) -> SKFilePath {
        let fileName = driveFileCacheName(cacheType: cacheType, fileToken: fileToken, dataVersion: dataVersion, fileExtension: fileExtension)
        return Self.downloadCacheURL.appendingRelativePath(fileName)
    }
}

// MARK: - helper functions
extension DriveCacheService {

    func getFileRecord(token: String) -> Record? {
        if let version = try? metaStorage.getVersion(for: token) {
            return try? metaStorage.getRecords(for: token).first(where: { $0.version == version })
        } else {
            return nil
        }
    }
    /// 过滤特定后缀的文件，若 record 的原始文件后缀获取失败，将会被过滤
    /// - Parameter fileExtension: 希望匹配的后缀，传 nil 表示不依据后缀过滤
    /// - Returns: fileExtension 为 nil 时，返回 nil
    func createExtensionFilter(fileExtension: String?) -> RecordFilter? {
        guard let fileExtension = fileExtension else { return nil }
        return {
            guard let sourceExtension = $0.originFileExtension else { return false }
            return sourceExtension.elementsEqual(fileExtension)
        }
    }
    
    // drive预览场景不指定cacheType的情况下，默认过滤掉origin类型
    func createPreviewExtensionFilter(fileExtension: String?) -> RecordFilter? {
        guard let fileExtension = fileExtension else {
            return { [weak self] in
                guard let self = self else { return false }
                return self.previewCacheType(cacheType: $0.recordType)
            }
        }
        return { [weak self] in
            guard let self = self else { return false }
            guard let sourceExtension = $0.originFileExtension else { return false }
            return sourceExtension.elementsEqual(fileExtension) && self.previewCacheType(cacheType: $0.recordType)
        }
    }
    
    private func previewCacheType(cacheType: DriveCacheType) -> Bool {
        switch cacheType {
        case .origin, .unknown:
            return false
        case .similar, .preview:
            return true
        case .associate:
            return cacheType.offlineAvailable
        }
    }

    
    /// 过滤特定版本的文件，并按需要过滤不支持离线打开的文件
    /// - Parameters:
    ///   - version: 希望匹配的版本
    ///   - needCheckReachability: 是否需要检查网络状况，需要且无网时，会过滤掉不可离线使用的文件
    ///   - additionalFilter: 其他额外的判断条件
    private func createRecordFilter(version: String, needCheckReachability: Bool, additionalFilter: RecordFilter?) -> RecordFilter {
        let needCheckOfflineAvailable = needCheckReachability && !DocsNetStateMonitor.shared.isReachable
        return {
            guard $0.version == version else { return false }
            if needCheckOfflineAvailable {
                guard $0.recordType.offlineAvailable else { return false }
            }
            return additionalFilter?($0) ?? true
        }
    }

    /// 根据缓存类型获取缓存实例
    private func getCache(type: CacheType) -> DriveCache {
        switch type {
        case .transient:
            return transientCache
        case .persistent:
            return persistentCache
        }
    }

    /// 解包version的便捷方法
    /// - Parameters:
    ///   - version: 希望使用的版本，nil 表示读取缓存中的默认值
    /// - Throws: 当传入的 version 为 nil，且缓存中取不到默认值，抛出 CacheError.versionNotFound
    /// - Returns: 传入的 version 或缓存中的默认 version
    private func getVersion(for token: String, version: String?) throws -> String {
        let cacheVersion = try metaStorage.getVersion(for: token)
        guard let version = version ?? cacheVersion else {
            throw CacheError.versionNotProvided
        }
        return version
    }

    private func getRecords(for token: String) throws -> Set<Record> {
        return try metaStorage.getRecords(for: token)
    }

    private func getValidRecord(from records: Set<Record>, filter: RecordFilter) throws -> Record {
        guard let validRecord = records.first(where: filter) else { throw CacheError.noValidRecordFound }
        return validRecord
    }

    func getCacheType(source: Source) -> CacheType {
        switch source {
        case .manual, .docsManual:
            return .persistent
        case .history, .standard, .docsImage, .tmp, .thirdParty:
            return .transient
        }
    }

    private func getCache(for record: Record) throws -> DriveCache {
        return getCache(type: record.cacheType)
    }
}

// MARK: - Checking Cache Existance
extension DriveCacheService {
    func canOpenOffline(token: String, dataVersion: String?, fileExtension: String?) -> Bool {
        return isDriveFileExist(token: token, dataVersion: dataVersion, fileExtension: fileExtension)
    }
    
    func isPDFFileExist(token: String, dataVersion: String?, fileExtension: String?) -> Bool {
        if isDriveFileExist(token: token, dataVersion: dataVersion, fileExtension: fileExtension) {
            return true
        } else if (try? getDriveData(type: .partialPDF, token: token, dataVersion: dataVersion, fileExtension: "pdf").get()) != nil {
            return true
        } else {
            return false
        }
    }
    
    func isDriveFileExist(token: String, dataVersion: String?, fileExtension: String?) -> Bool {
        // 没有指定cacheType，过滤掉orign类型
        DocsLogger.driveInfo("drive.file.cache --- drive file exist", extraInfo: ["token": DocsTracker.encrypt(id: token),
                                                                             "version": dataVersion ?? "",
                                                                             "fileExtension": fileExtension ?? ""])
        let extensionFilter = createPreviewExtensionFilter(fileExtension: fileExtension)
        return isFileExist(token: token, version: dataVersion) { !self.isImageCover(cacheType: $0.recordType) && (extensionFilter?($0) ?? true) }
    }

    func isDriveFileExist(type: DriveCacheType, token: String, dataVersion: String?, fileExtension: String?) -> Bool {
        // 指定了DriveCacheType，根据指定的cacheType获取文件
        let extensionFilter = createExtensionFilter(fileExtension: fileExtension)
        return isFileExist(token: token, version: dataVersion) { $0.recordType == type && (extensionFilter?($0) ?? true) }
    }

    func isFileExist(token: String, version: String?, filter: RecordFilter? = nil) -> Bool {
        return cacheQueue.sync {
            unsafeIsFileExist(token: token, version: version, filter: filter)
        }
    }

    private func unsafeIsFileExist(token: String, version: String?, filter: RecordFilter? = nil) -> Bool {
        DocsLogger.driveInfo("drive.file.cache --- check file existence", extraInfo: ["token": DocsTracker.encrypt(id: token)])
        do {
            let version = try getVersion(for: token, version: version)
            let records = try getRecords(for: token)
            let recordInfos = records.map({ $0.recordType.identifier })
            DocsLogger.driveInfo("drive.file.cache --- record types \(recordInfos)")
            let recordFilter = createRecordFilter(version: version, needCheckReachability: true, additionalFilter: filter)
            let validRecord = try getValidRecord(from: records, filter: recordFilter)
            let cache = try getCache(for: validRecord)
            guard cache.isFileExist(record: validRecord) else {
                DocsLogger.driveInfo("drive.file.cache --- cache can not find record")
                clean(invalidRecord: validRecord)
                return false
            }
            return true
        } catch {
            DocsLogger.driveInfo("drive.file.cache --- check file existence failed", extraInfo: ["token": DocsTracker.encrypt(id: token)], error: error)
            return false
        }
    }
}

// MARK: - Get File Operations
extension DriveCacheService {

    /// 包装缓存中的原始文件供第三方打开使用
    /// - Note: 线程安全，同步操作，若缓存线程中有其他操作则会阻塞调用线程
    /// - Parameters:
    ///   - token: 文件 token
    ///   - dataVersion: 文件 dataVersion
    ///   - fileExtension: 文件后缀名
    /// - Returns: 第三方打开数据源对象
    func getDriveItemProvider(token: String, dataVersion: String?, fileExtension: String?, encryptIfNeed: Bool = false) -> DriveCacheItemProvider? {

        guard case var .success(file) = getDriveFile(type: .origin, token: token, dataVersion: dataVersion, fileExtension: fileExtension) else {
            DocsLogger.warning("drive.file.cache --- Failed to get origin file when generate 3rd open item provider")
            return nil
        }
        guard let filePath = file.fileURL else {
            spaceAssertionFailure("drive.file.cache --- fileURL not set")
            return nil
        }
        var isEncrypt = false
        if encryptIfNeed, CacheService.isDiskCryptoEnable() {
            if let encryptUrl = filePath.getEncryptFile() {
                DocsLogger.driveInfo("[KACrypto] encrypt befor open with 3rd app")
                isEncrypt = true
                file = Node(record: file.record, fileName: file.fileName, fileSize: file.fileSize, fileURL: encryptUrl)
            } else {
                DocsLogger.driveError("[KACrypto] encrypt befor open with app error")
            }
        }
        let itemProvider = DriveCacheItemProvider(file: file, tmpURL: Self.otherTmpURL, isEncrypt: isEncrypt)
        return itemProvider
    }

    /// 本地文件使用第三方打开时复制文件供第三方打开使用
    ///
    /// - Parameters:
    ///   - pathURL: 本地文件路径
    ///   - fileName: 显示的文件名
    /// - Returns: 复制后的路径地址
    func getItemURL(pathURL: SKFilePath, fileName: String, encryptIfNeed: Bool = false) -> SKFilePath {
        let tmpURL = Self.otherTmpURL.appendingRelativePath(fileName)
        guard pathURL.copyItem(to: tmpURL, overwrite: true) else {
            DocsLogger.warning("drive.file.cache --- Failed to rename file when copying for 3rd Open.")
            return pathURL
        }
        if encryptIfNeed, CacheService.isDiskCryptoEnable() {
            if let encryptUrl = tmpURL.getEncryptFile() {
                DocsLogger.driveInfo("[KACrypto] encrypt befor open with 3rd app")
                return encryptUrl
            } else {
                DocsLogger.driveError("[KACrypto] encrypt befor open with app error")
            }
        }
        return tmpURL
    }

    func getDriveFile(token: String, dataVersion: String?, fileExtension: String?) -> Result<Node, Error> {
        // 没有指定cacheType，过滤掉orign类型
        let extensionFilter = createPreviewExtensionFilter(fileExtension: fileExtension)
        return getFile(token: token, version: dataVersion) { !self.isImageCover(cacheType: $0.recordType) && (extensionFilter?($0) ?? true) }
    }

    func getDriveFile(type: DriveCacheType, token: String, dataVersion: String?, fileExtension: String?) -> Result<Node, Error> {
        let extensionFilter = createExtensionFilter(fileExtension: fileExtension)
        // 指定了DriveCacheType，根据制定的cacheType获取文件
        return getFile(token: token, version: dataVersion) { $0.recordType == type && (extensionFilter?($0) ?? true) }
    }

    func getFile(token: String, version: String?, filter: RecordFilter? = nil) -> Result<Node, Error> {
        return cacheQueue.sync {
            autoreleasepool {
                unsafeGetFile(token: token, version: version, filter: filter)
            }
        }
    }

    private func unsafeGetFile(token: String, version: String?, filter: RecordFilter?) -> Result<Node, Error> {
        DocsLogger.driveInfo("drive.file.cache --- getting file", extraInfo: ["token": DocsTracker.encrypt(id: token)])
        do {
            let version = try getVersion(for: token, version: version)
            let recordsForToken = try getRecords(for: token)
            let recordInfos = recordsForToken.map({ $0.recordType.identifier })
            DocsLogger.driveInfo("drive.file.cache --- record types \(recordInfos), version: \(version)")
            let recordFilter = createRecordFilter(version: version, needCheckReachability: false, additionalFilter: filter)
            let validRecord = try getValidRecord(from: recordsForToken, filter: recordFilter)
            let cache = try getCache(for: validRecord)
            let result = cache.getFile(record: validRecord)
            switch result {
            case let .failure(error):
                // 如果 record 没有获取到对应的 node，说明文件可能被删掉了，或者改过名字后缀不匹配，需要清理record的记录
                DocsLogger.driveError("drive.file.cache --- get file failed", error: error)
                clean(invalidRecord: validRecord)
                return .failure(error)
            case let .success(node):
                return .success(node)
            }
        } catch CacheError.recordsNotFound {
            DocsLogger.driveInfo("drive.file.cache --- get file failed, records not found, cleaning tokenVersionMap", extraInfo: ["token": DocsTracker.encrypt(id: token)])
            // token 找不到相关的记录，需要清空对应的默认 version
            try? metaStorage.deleteVersion(with: token)
            return .failure(CacheError.recordsNotFound)
        } catch let CacheError.determineCacheFailed(invalidRecord) {
            // 如果没有取到 record 对应的 storageType，说明保存的时候没有正确更新记录，在这里把record清理掉
            clean(invalidRecord: invalidRecord)
            spaceAssertionFailure("drive.file.cache --- get file failed, cache for record not found")
            DocsLogger.driveInfo("drive.file.cache --- get file failed, cache for record not found", extraInfo: ["token": DocsTracker.encrypt(id: token)])
            return .failure(CacheError.determineCacheFailed(record: invalidRecord))
        } catch {
            DocsLogger.driveInfo("drive.file.cache --- get file failed", extraInfo: ["token": DocsTracker.encrypt(id: token)], error: error)
            return .failure(error)
        }
    }
    
    private func isImageCover(cacheType: DriveCacheType) -> Bool {
        switch cacheType {
        case let .associate(customID):
            return customID.hasPrefix("image-cover")
        default:
            return false
        }
    }
}

// MARK: - saving file into cache
extension DriveCacheService {

    typealias SaveCompletion = (Result<SKFilePath, Error>) -> Void

    func saveDriveFile(context: SaveFileContext, completion: SaveCompletion? = nil) {
        let cacheType = getCacheType(source: context.basicInfo.source)
        let fileSize = context.basicInfo.originFileSize ?? context.filePath.fileSize
        let record = Record(token: context.basicInfo.token,
                            version: context.basicInfo.dataVersion ?? "",
                            recordType: context.basicInfo.cacheType,
                            originName: context.basicInfo.fileName,
                            originFileSize: fileSize,
                            fileType: context.basicInfo.fileType,
                            cacheType: cacheType)
        saveFile(filePath: context.filePath,
                 record: record,
                 source: context.basicInfo.source,
                 moveInsteadOfCopy: context.moveInsteadOfCopy,
                 rewriteFileName: context.rewriteFileName,
                 completion: completion)
    }

    func saveFile(filePath: SKFilePath, record: Record, source: Source, moveInsteadOfCopy: Bool = true, rewriteFileName: Bool, completion: SaveCompletion? = nil) {
         guard DriveFeatureGate.driveEnabled || source.allowWhenDriveDisabled else {
            completion?(.failure(CacheError.driveDisabledByFG))
            return
        }
        
        cacheQueue.async {
            self.unsafeSave(filePath: filePath, record: record, source: source, moveInsteadOfCopy: moveInsteadOfCopy, rewriteFileName: rewriteFileName, completion: completion)
        }
    }

    private func unsafeSave(filePath: SKFilePath, record: Record, source: Source, moveInsteadOfCopy: Bool = true, rewriteFileName: Bool, completion: SaveCompletion? = nil) {
        let cache = getCache(type: record.cacheType)
        DocsLogger.driveInfo("drive.file.cache --- saving file", extraInfo: ["token": DocsTracker.encrypt(id: record.token), "cacheType": record.cacheType.rawValue])
        let result = cache.saveFile(fileURL: filePath, record: record, moveInsteadOfCopy: moveInsteadOfCopy, rewriteFileName: rewriteFileName).mapError { $0 as Error }
        switch result {
        case let .failure(error):
            DocsLogger.driveError("drive.file.cache --- save file failed", extraInfo: ["token": DocsTracker.encrypt(id: record.token), "cacheType": record.cacheType.rawValue], error: error)
        case .success:
            do {
                try didSave(record: record, source: source, cacheType: record.cacheType)
            } catch {
                DocsLogger.driveError("drive.file.cache --- didsave update db failed", extraInfo: ["token": DocsTracker.encrypt(id: record.token)], error: error)
            }
        }
        DispatchQueue.main.async {
            completion?(result)
        }
    }

    private func didSave(record: Record, source: Source, cacheType: CacheType) throws {
        DocsLogger.driveInfo("drive.file.cache --- save succeed", extraInfo: ["token": DocsTracker.encrypt(id: record.token)])
        
        let token = record.token
        let version = record.version
        switch source {
        case .manual, .docsManual:
            if let oldVersion = try metaStorage.getVersion(for: token), oldVersion != version {
                unsafeDelete(token: token, version: oldVersion)
            }
            if !version.isEmpty {
                try metaStorage.insertVersion(version, with: token)
            } else {
                DocsLogger.driveError("drive.file.cache --- save version is empty", extraInfo: ["token": DocsTracker.encrypt(id: record.token)])
            }
            
        case .history:
            break
        case .standard:
            try metaStorage.insertVersion(version, with: token)
        case .docsImage:
            if !version.isEmpty {
                try metaStorage.insertVersion(version, with: token)
            }
        case .tmp, .thirdParty: // 没有version信息
            break
        }
        try metaStorage.insert(record: record)
    }
}

// MARK: - deleting file in cache
extension DriveCacheService {

    typealias DeleteCompletion = (_ success: Bool) -> Void

    func deleteDriveFile(token: String, dataVersion: String?, completion: DeleteCompletion? = nil) {
        deleteFile(token: token, version: dataVersion, completion: completion)
    }

    func deleteFile(token: String, version: String?, filter: RecordFilter? = nil, completion: DeleteCompletion?) {
        cacheQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            let result = self.unsafeDelete(token: token, version: version, filter: filter)
            DispatchQueue.main.async {
                completion?(result)
            }
        }
    }

    /// 删除指定 token 的特定 version 文件，若 version 为nil，则删除所有token相关的文件
    @discardableResult
    private func unsafeDelete(token: String, version: String?, filter: RecordFilter? = nil) -> Bool {
        let recordFilter: RecordFilter?
        if let version = version {
            recordFilter = createRecordFilter(version: version, needCheckReachability: false, additionalFilter: filter)
        } else {
            recordFilter = filter
        }
        return unsafeDelete(token: token, filter: recordFilter)
    }

    /// 删除指定 token 的所有文件
    @discardableResult
    private func unsafeDelete(token: String, filter: RecordFilter? = nil) -> Bool {
        DocsLogger.driveInfo("drive.file.cache --- deleting file", extraInfo: ["token": DocsTracker.encrypt(id: token)])
        do {
            let recordsForToken = try getRecords(for: token)
            let records: Set<Record>
            if let filter = filter {
                records = recordsForToken.filter(filter)
            } else {
                records = recordsForToken
            }
            if records.isEmpty { throw CacheError.noValidRecordFound }
            records.forEach { record in
                unsafeDelete(record: record)
            }
            return true
        } catch CacheError.recordsNotFound {
            DocsLogger.driveError("drive.file.cache --- delete file failed, records not found, clean up tokenVersionMap", extraInfo: ["token": DocsTracker.encrypt(id: token)])
            do {
                try metaStorage.deleteVersion(with: token)
            } catch {
                DocsLogger.driveError("drive.file.cache --- delete version failed", extraInfo: ["token": DocsTracker.encrypt(id: token)], error: error)
            }
            return false
        } catch {
            DocsLogger.driveError("drive.file.cache --- delete file failed", extraInfo: ["token": DocsTracker.encrypt(id: token)], error: error)
            return false
        }
    }

    /// 删除指定的 Record
    @discardableResult
    private func unsafeDelete(record: Record) -> Bool {
        let token = record.token
        DocsLogger.driveInfo("drive.file.cache --- deleting file with record", extraInfo: ["token": DocsTracker.encrypt(id: token)])
        guard let cache = try? getCache(for: record) else {
            DocsLogger.driveError("drive.file.cache --- delete record failed, cache type not found")
            return false
        }
        cache.deleteFile(record: record)
        clean(invalidRecord: record)
        return false
    }

    private func clean(invalidRecord: Record) {
        do {
            try metaStorage.deleteRecord(invalidRecord)
        } catch {
            DocsLogger.driveInfo("drive.file.cache --- clean invalid record failed", extraInfo: ["token": DocsTracker.encrypt(id: invalidRecord.token)], error: error)
        }
    }

    func deleteAll(completion: (() -> Void)? = nil) {
        cacheQueue.async {
            self.unsafeDeleteAll()
        }
    }

    private func unsafeDeleteAll(completion: (() -> Void)? = nil) {
        cleanUpTmpURLs()
        transientCache.deleteAll()
        persistentCache.deleteAll()
        do {
            try metaStorage.clean()
        } catch {
            DocsLogger.driveError("drive.file.cache --- clean storage failed", error: error)
        }
        completion?()
    }
}

// MARK: - Transfer Node Between Cache
extension DriveCacheService {

    @discardableResult
    private func transfer(record: Record, from: CacheType, to: CacheType) -> Bool {
        let token = record.token
        guard from != to else {
            DocsLogger.driveInfo("drive.file.cache --- transfer record into cache with same name, ignored",
                            extraInfo: ["from-type": from, "to-type": to, "token": DocsTracker.encrypt(id: token)])
            return true
        }
        DocsLogger.driveInfo("drive.file.cache --- start transfering record",
                        extraInfo: ["from-type": from, "to-type": to, "token": DocsTracker.encrypt(id: token)])
        let fromCache = getCache(type: from)
        let toCache = getCache(type: to)
        guard case let .success(node) = fromCache.getFile(record: record) else {
            DocsLogger.driveError("drive.file.cache --- transfer record failed, unable to get node")
            return false
        }
        guard let filePath = node.fileURL else {
            spaceAssertionFailure("drive.file.cache --- cache node file url not set")
            return false
        }
        guard case .success = toCache.saveFile(fileURL: filePath, record: record, rewriteFileName: false) else {
            DocsLogger.driveError("drive.file.cache --- transfer record failed, unable to save node in new cache")
            return false
        }
        fromCache.deleteFile(record: record)
        var newRecord = record
        newRecord.cacheType = to
        do {
            try metaStorage.insert(record: newRecord)
            DocsLogger.driveInfo("drive.file.cache --- transfer record complete")
        } catch {
            DocsLogger.driveError("drive.file.cache --- transfer record failed, unable to update record cacheType in DB", extraInfo: ["token": DocsTracker.encrypt(id: token)], error: error)
            return false
        }
        return true
    }

    func moveToManualOffline(files: [(token: String, dataVersion: String?, fileExtension: String?)], complete: (() -> Void)?) {
        cacheQueue.async {
            files.forEach { (token, dataVersion, fileExtension) in
                self.unsafeMoveToManualOffline(token: token, version: dataVersion, fileExtension: fileExtension)
            }
            complete?()
        }
    }

    private func unsafeMoveToManualOffline(token: String, version: String?, fileExtension: String?) {
        // 没有指定cacheType，过滤掉orign类型
        let extensionFilter = createPreviewExtensionFilter(fileExtension: fileExtension)
        do {
            let version = try getVersion(for: token, version: version)
            // 找到后缀匹配且可离线使用的缓存文件
            let recordFilter = createRecordFilter(version: version, needCheckReachability: true, additionalFilter: extensionFilter)
            let recordsForToken = try getRecords(for: token)
            let validRecord = try getValidRecord(from: recordsForToken, filter: recordFilter)
            transfer(record: validRecord, from: .transient, to: .persistent)
        } catch {
            DocsLogger.driveError("drive.file.cache --- move to manual offline failed", error: error)
            return
        }
    }

    func moveOutManualOffline(tokens: [String], complete: (() -> Void)?) {
        cacheQueue.async {
            tokens.forEach(self.unsafeMoveOutManualOffline(token:))
            complete?()
        }
    }

    private func unsafeMoveOutManualOffline(token: String) {
        do {
            let persistentRecords = try metaStorage.getRecords(for: token, cacheType: .persistent)
            persistentRecords.forEach { transfer(record: $0, from: .persistent, to: .transient) }
        } catch {
            DocsLogger.driveError("drive.file.cache --- move to manual offline failed", error: error)
        }
    }
}

// MARK: - Data Interface
extension DriveCacheService {
    func saveDriveData(context: SaveDataContext, completion: SaveCompletion? = nil) {
        DispatchQueue.global().async {
            let dataFileURL = self.driveFileDownloadURL(cacheType: context.basicInfo.cacheType,
                                                        fileToken: context.basicInfo.token,
                                                        dataVersion: context.basicInfo.dataVersion ?? "default",
                                                        fileExtension: "bin")
            guard dataFileURL.writeFile(with: context.data, mode: .over) else {
                DocsLogger.driveError("drive.file.cache --- failed to save drive data, write data failed")
                completion?(.failure(CacheError.writeDataFailed))
                return
            }
            let saveContext = SaveFileContext(filePath: dataFileURL,
                                              moveInsteadOfCopy: true,
                                              basicInfo: context.basicInfo,
                                              rewriteFileName: false)
            self.saveDriveFile(context: saveContext, completion: completion)
        }
    }

    func getDriveData(type: DriveCacheType, token: String, dataVersion: String?, fileExtension: String?) -> Result<(Node, Data), Error> {
        let result = getDriveFile(type: type, token: token, dataVersion: dataVersion, fileExtension: fileExtension)
        let encrypedToken = token.encryptToken
        
        switch result {
        case let .failure(error):
            DocsLogger.driveInfo("drive.file.cache --- failed to get drive data for token: \(encrypedToken)", error: error)
            return .failure(error)
        case let .success(node):
            guard let filePath = node.fileURL else {
                spaceAssertionFailure("drive.file.cache --- cache node file url not set")
                let error = NSError(domain: "drive.file.cache", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "cache node file url not set"
                ])
                return .failure(error)
            }
            do {
                let data = try Data.read(from: filePath)
                return .success((node, data))
            } catch {
                DocsLogger.driveError("drive.file.cache --- failed to get drive data for token: \(encrypedToken), read data from file failed with error", error: error)
                return .failure(error)
            }
        }
    }
}

extension DriveCacheService: DriveCacheServiceBase {
    func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile], completion: (() -> Void)?) {
        DocsLogger.driveInfo("drive.file.cache --- start to clear data in simple mode", component: LogComponents.simpleMode)
        cacheQueue.async {
            let fileTokens = files.map { $0.objToken }
            fileTokens.forEach {
                self.unsafeDelete(token: $0)
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    // 切换租户重置connection、cache实例
    func userDidLogout() {
        innerPersistent = nil
        innerTransient = nil
        metaStorage.reset()
    }
}

extension DriveCacheService: DriveCacheServiceProtocol {
}
