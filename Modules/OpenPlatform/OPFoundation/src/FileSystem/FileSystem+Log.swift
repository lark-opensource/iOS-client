//
//  FileSystem+Log.swift
//  TTMicroApp
//
//  Created by Meng on 2021/11/1.
//

import Foundation
import LarkCache
import LarkAccountInterface
import CommonCrypto
import LarkRustClient
import ECOProbe
import LKCommonsLogging

public final class FileSystemLog {
    /// /Library/cache/com.filesystem.openplatform
    public class var cacheDir: String {
        return CacheDirectory.cache.path + "/com.filesystem.openplatform"
    }

    /// LarkUser_{user_id}
    public class var currentLogFileName: String {
        // TODOZJX
        return "LarkUser_" + AccountServiceAdapter.shared.currentChatterId
    }

    /// filelog
    public static let logExtension: String = "filelog"
    private static let logFileVersion: UInt8 = 1
    private static let logBlockVersion: UInt8 = 1
    private static let logFileMaxSize: UInt64 = 50 * 1024 * 1024 // 50MB
    private static let logFileBlockSize: UInt64 = 8 * 1024       // 8KB
    private static let logFilePruneBufferSize: Int = 8 * 1024
    private static let jsonEncoder = JSONEncoder()

    static let logger = Logger.oplog(FileSystemLog.self, category: "FileSystem.Log")

    static let `default` = FileSystemLog()

    private var cacheLogFileInfo: LogFileInfo?
    private let queue = DispatchQueue(label: "com.filelog.filesystem.openplatform")

    init() {}

    deinit {
        if let fileInfo = cacheLogFileInfo {
            fileInfo.fileHandle.closeFile()
            cacheLogFileInfo = nil
        }
    }

    func logFile(_ file: FileObject, filePath: String, api: FileSystem.PrimitiveAPI, context: FileSystem.Context) {
        guard FileSystemUtils.getCryptoConfig().enableFileLog else { return }
        queue.sync {
            _logFile(file, filePath: filePath, api: api, context: context)
        }
    }

    private func _logFile(_ file: FileObject, filePath: String, api: FileSystem.PrimitiveAPI, context: FileSystem.Context) {
        do {
            var logFileInfo = try loadLogFileInfo(context)
            let fileURL = URL(fileURLWithPath: filePath)
            let fileHandle = try LSFileSystem.main.fileReadingHandle(filePath: filePath)

            /// 如果已经写到末尾，则重新指向头部，并更新 header
            if logFileInfo.header.position == Self.logFileMaxSize {
                logFileInfo.header.position = UInt32(LogFileHeader.headerSize)
            }

            /// 计算原始文件 meta
            let fileMeta = try buildFileMeta(
                file,
                filePath: filePath,
                fileHandle: fileHandle,
                api: api,
                context: context
            )
            let metaData = try Self.jsonEncoder.encode(fileMeta)
            let metaSize = UInt64(metaData.count)

            /// meta 超过最大写入大小
            let maxMetaSize = Self.logFileBlockSize - LogFileHeader.headerSize /** 8KB - 5 */
            guard metaSize <= maxMetaSize else {
                Self.logger.error("file meta data size over max meta size in block", additionalData: [
                    "metaSize": "\(metaSize)",
                    "metaInfo": fileMeta.description
                ])
                return
            }

            /// 计算 first block file data size
            let firstBlockDataMaxSize = Self.logFileBlockSize - LogBlockHeader.headerSize - metaSize
            var firstBlockDataSize: UInt64 = 0              /** file 数据块写入长度 */
            var firstBlockPlaceholderDataSize: UInt64 = 0   /** 长度不足，补零的长度 */
            if fileMeta.size <= firstBlockDataMaxSize {
                firstBlockDataSize = fileMeta.size
                firstBlockPlaceholderDataSize = firstBlockDataMaxSize - fileMeta.size
            } else {
                firstBlockDataSize = firstBlockDataMaxSize
                firstBlockPlaceholderDataSize = 0
            }

            /// 计算 first block header 内容
            let firstBlockHeader = LogBlockHeader(
                version: Self.logBlockVersion,
                metaLength: UInt16(truncatingIfNeeded: metaSize),
                dataLength: UInt16(truncatingIfNeeded: firstBlockDataSize)
            )

            Self.logger.info("start write log file", additionalData: [
                "fileMeta": fileMeta.description,
                "pos": "\(logFileInfo.fileHandle.offsetInFile)",
                "metaSize": "\(metaData.count)",
                "dataSize": "\(firstBlockDataSize)",
                "placeHolderSize": "\(firstBlockPlaceholderDataSize)",
                "fileSize": "\(fileMeta.size)"
            ])

            /// 写入 first block header data
            logFileInfo.fileHandle.write(firstBlockHeader.data)

            /// 写入 first block meta data
            logFileInfo.fileHandle.write(metaData)

            /// 写入 firt block file data
            fileHandle.seek(toFileOffset: 0)  /* 文件指针归零，从头部开始读取 */
            let firstBlockData = fileHandle.readData(ofLength: Int(firstBlockDataSize))
            logFileInfo.fileHandle.write(firstBlockData)

            if firstBlockPlaceholderDataSize > 0 {
                let placeholderData = Data([UInt8](repeating: 0, count: Int(firstBlockPlaceholderDataSize)))
                logFileInfo.fileHandle.write(placeholderData)
            }

            assert(
                UInt64(firstBlockHeader.data.count)
                + metaSize
                + UInt64(firstBlockData.count)
                + firstBlockPlaceholderDataSize == Self.logFileBlockSize
            )

            /// 更新 position
            logFileInfo.header.position += UInt32(Self.logFileBlockSize)

            let defaultBlockDataSize = Self.logFileBlockSize - LogBlockHeader.headerSize - 0 /* meta size */

            /// 循环按块写入剩余文件数据
            while fileHandle.offsetInFile < fileMeta.size {
                autoreleasepool {
                    /// 如果已经写到末尾，则重新指向头部，并更新 header
                    if logFileInfo.header.position == Self.logFileMaxSize {
                        logFileInfo.header.position = UInt32(LogFileHeader.headerSize)
                    }

                    /// 计算本次 block 迭代文件写入数据大小
                    var dataSize: UInt64 = 0
                    var placeHolderDataSize: UInt64 = 0
                    if fileMeta.size - fileHandle.offsetInFile < defaultBlockDataSize {
                        dataSize = fileMeta.size - fileHandle.offsetInFile
                        placeHolderDataSize = defaultBlockDataSize - dataSize
                    } else {
                        dataSize = defaultBlockDataSize
                        placeHolderDataSize = 0
                    }

                    /// 计算写入 header
                    let blockHeader = LogBlockHeader(
                        version: Self.logBlockVersion,
                        metaLength: 0,
                        dataLength: UInt16(truncatingIfNeeded: dataSize)
                    )

                    /// 读取写入数据
                    let fileData = fileHandle.readData(ofLength: Int(truncatingIfNeeded: dataSize))

                    /// 写入 header
                    logFileInfo.fileHandle.write(blockHeader.data)
                    /// 写入 file data
                    logFileInfo.fileHandle.write(fileData)

                    /// 写入 placeholder data (补0）
                    if placeHolderDataSize > 0 {
                        let placeholderData = Data([UInt8](repeating: 0, count: Int(truncatingIfNeeded: placeHolderDataSize)))
                        logFileInfo.fileHandle.write(placeholderData)
                    }

                    assert(
                        UInt64(blockHeader.data.count)
                        + UInt64(fileData.count)
                        + placeHolderDataSize == Self.logFileBlockSize
                    )
                    /// 更新 position
                    logFileInfo.header.position += UInt32(Self.logFileBlockSize)
                }
            }

            fileHandle.closeFile()
            logFileInfo.fileHandle.synchronizeFile()
            Self.logger.info("log file end", additionalData: ["pos": "\(logFileInfo.fileHandle.offsetInFile)"])
        } catch {
            context.trace.error("log file failed", error: error)
        }
    }

    /// 构建 文件 log meta 信息
    private func buildFileMeta(
        _ file: FileObject,
        filePath: String,
        fileHandle: FileHandle,
        api: FileSystem.PrimitiveAPI,
        context: FileSystem.Context
    ) throws -> FileMeta {
        let attributes = try LSFileSystem.attributesOfItem(atPath: filePath) as NSDictionary
        var createDate: Int64?
        if let fileCreateTimeInterval = attributes.fileCreationDate()?.timeIntervalSince1970 {
            createDate = Int64(fileCreateTimeInterval * 1000)
        }

        var modifyDate: Int64?
        if let fileModifyTimeInterval = attributes.fileModificationDate()?.timeIntervalSince1970 {
            modifyDate = Int64(fileModifyTimeInterval * 1000)
        }
        
        // TODOZJX
        return FileMeta(
            path: file.rawValue,
            size: attributes.fileSize(),
            createDate: createDate,
            modifyDate: modifyDate,
            md5: try calculateFileMD5(fileHandle),
            userId: AccountServiceAdapter.shared.currentChatterId,
            tenantId: AccountServiceAdapter.shared.currentTenant.tenantId,
            appId: context.uniqueId.appID,
            appType: OPAppTypeToString(context.uniqueId.appType),
            tag: context.tag,
            primitiveAPI: api.rawValue,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }

    private func loadLogFileInfo(_ context: FileSystem.Context) throws -> LogFileInfo {
        let currentLogFileURL = URL(fileURLWithPath: Self.cacheDir)
            .appendingPathComponent(Self.currentLogFileName)
            .appendingPathExtension(Self.logExtension)

        context.trace.info("load logInfo", additionalData: ["path": currentLogFileURL.path])
        /// 不存在则创建一个 logfile 文件, 包括它所在的文件夹
        let logFileExist = LSFileSystem.fileExists(filePath: currentLogFileURL.path)
        if !logFileExist {
            /// 用户可能在运行期间清理 log 文件，这里每次 load 时需要判断，如果不存在则需要清理缓存上下文
            self.cacheLogFileInfo?.fileHandle.closeFile()
            self.cacheLogFileInfo = nil
            try LSFileSystem.fileLog.createDirectory(atPath: Self.cacheDir, withIntermediateDirectories: true, attributes: nil)
            let createResult = LSFileSystem.fileLog.createFile(atPath: currentLogFileURL.path, contents: nil)
            context.trace.info("logfile not exist, create result: \(createResult)")
        }

        /// 判断是否有 fileinfo 缓存
        if let fileInfo = self.cacheLogFileInfo {
            if fileInfo.url == currentLogFileURL {
                return fileInfo
            } else {
                fileInfo.fileHandle.closeFile()
                self.cacheLogFileInfo = nil
            }
        }

        context.trace.info("load logInfo with not cache, rebuild", additionalData: ["exist": "\(logFileExist)"])

        /// 创建FileInfo，并构建文件头信息
        var fileHandle = try LSFileSystem.fileLog.fileUpdatingHandle(filePath: currentLogFileURL.path)
        var fileHeader: LogFileHeader

        /// 尝试读取原始头信息，不存在时则清理掉重新创建
        if logFileExist {
            let fileHeaderData = fileHandle.readData(ofLength: Int(LogFileHeader.headerSize))
            if let header = LogFileHeader(data: fileHeaderData) {
                fileHeader = header
            } else {
                // 读取失败，清理原文件后重新创建, 并写入初始数据
                context.trace.error("read logfile header failed", additionalData: ["headerDataSize": "\(fileHeaderData.count)"])
                fileHandle.closeFile()
                try LSFileSystem.fileLog.removeItem(atPath: currentLogFileURL.path)
                LSFileSystem.fileLog.createFile(atPath: currentLogFileURL.path, contents: nil)
                fileHeader = LogFileHeader(version: Self.logFileVersion, position: UInt32(LogFileHeader.headerSize))
                fileHandle = try LSFileSystem.fileLog.fileUpdatingHandle(filePath: currentLogFileURL.path)
            }
        } else {
            fileHeader = LogFileHeader(version: Self.logFileVersion, position: UInt32(LogFileHeader.headerSize))
            fileHandle.write(fileHeader.data)
        }

        let fileInfo = LogFileInfo(url: currentLogFileURL, header: fileHeader, fileHandle: fileHandle)
        self.cacheLogFileInfo = fileInfo

        return fileInfo
    }

    /// TODO: 将来做优化和下沉
    private func calculateFileMD5(_ fileHandle: FileHandle) throws -> String {
        var context = CC_MD5_CTX()
        let bufferSize = 1024 * 8
        CC_MD5_Init(&context)
        fileHandle.seek(toFileOffset: 0)
        while case let data = fileHandle.readData(ofLength: bufferSize), data.count > 0 {
            data.withUnsafeBytes({
                _ = CC_MD5_Update(&context, $0, CC_LONG(data.count))
            })
        }
        var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes({
            _ = CC_MD5_Final($0, &context)
        })
        return digest.map({ String(format: "%02hhx", $0) }).joined()
    }
}

/// Log 文件 header
/// 1 byte: version
/// 4 bytes: 写入数据位置
/// 5 ~ 8K: 保留数据空间，默认为 0
struct LogFileHeader {
    static let headerSize: UInt64 = 8 * 1024 // 8KB

    let version: UInt8
    var position: UInt32

    init(version: UInt8, position: UInt32) {
        self.version = version
        self.position = position
    }

    init?(data: Data) {
        guard data.count == Self.headerSize else {
            return nil
        }

        let bytes = data.bytes
        self.version = bytes[0]
        if version == 1 {
            self.position = 0
            self.position += UInt32(bytes[1]) << 24
            self.position += UInt32(bytes[2]) << 16
            self.position += UInt32(bytes[3]) << 8
            self.position += UInt32(bytes[4])
        } else {
            return nil
        }
    }

    var data: Data {
        var dataArray: [UInt8] = [
            version,
            UInt8(truncatingIfNeeded: position >> 24),
            UInt8(truncatingIfNeeded: position >> 16),
            UInt8(truncatingIfNeeded: position >> 8),
            UInt8(truncatingIfNeeded: position)
        ]
        /// 保留长度
        dataArray.append(contentsOf: [UInt8](repeating: 0, count: Int(Self.headerSize) - dataArray.count))
        return Data(dataArray)
    }
}

/// Log文件数据块header
/// 1 Byte: version
/// 2 Bytes: meta 数据长度
/// 2 Bytes: data 数据长度
struct LogBlockHeader {
    static let headerSize: UInt64 = 5

    var version: UInt8
    var metaLength: UInt16
    var dataLength: UInt16

    var data: Data {
        return Data([
            version,
            UInt8(truncatingIfNeeded: metaLength >> 8),
            UInt8(truncatingIfNeeded: metaLength),
            UInt8(truncatingIfNeeded: dataLength >> 8),
            UInt8(truncatingIfNeeded: dataLength)
        ])
    }
}

class LogFileInfo {
    let url: URL
    var header: LogFileHeader {
        didSet { updateHeader() }
    }
    let fileHandle: FileHandle

    init(url: URL, header: LogFileHeader, fileHandle: FileHandle) {
        self.url = url
        self.header = header
        self.fileHandle = fileHandle

        self.fileHandle.seek(toFileOffset: UInt64(header.position))
    }

    private func updateHeader() {
        fileHandle.seek(toFileOffset: 0)
        fileHandle.write(header.data)
        fileHandle.seek(toFileOffset: UInt64(header.position))
    }
}

struct FileMeta: Codable, CustomStringConvertible {
    private enum CodingKeys: String, CodingKey {
        case path
        case size
        case createDate = "create_date"
        case modifyDate = "modify_date"
        case md5
        case userId = "user_id"
        case tenantId = "tenant_id"
        case appId = "app_id"
        case appType = "app_type"
        case tag
        case primitiveAPI = "primitive_api"
        case timestamp = "timestamp"
    }

    let path: String

    let size: UInt64
    let createDate: Int64?
    let modifyDate: Int64?
    let md5: String

    let userId: String
    let tenantId: String
    let appId: String
    let appType: String

    let tag: String
    let primitiveAPI: String

    let timestamp: Int64

    init(path: String,
         size: UInt64,
         createDate: Int64?,
         modifyDate: Int64?,
         md5: String,
         userId: String,
         tenantId: String,
         appId: String,
         appType: String,
         tag: String,
         primitiveAPI: String,
         timestamp: Int64
    ) {
        self.path = path
        self.size = size
        self.createDate = createDate
        self.modifyDate = modifyDate
        self.md5 = md5
        self.userId = userId
        self.tenantId = tenantId
        self.appId = appId
        self.appType = appType
        self.tag = tag
        self.primitiveAPI = primitiveAPI
        self.timestamp = timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try container.decode(String.self, forKey: .path)
        self.size = try container.decode(UInt64.self, forKey: .size)
        self.createDate = try container.decodeIfPresent(Int64.self, forKey: .createDate)
        self.modifyDate = try container.decodeIfPresent(Int64.self, forKey: .modifyDate)
        self.md5 = try container.decode(String.self, forKey: .md5)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.tenantId = try container.decode(String.self, forKey: .tenantId)
        self.appId = try container.decode(String.self, forKey: .appId)
        self.appType = try container.decode(String.self, forKey: .appType)
        self.tag = try container.decode(String.self, forKey: .tag)
        self.primitiveAPI = try container.decode(String.self, forKey: .primitiveAPI)
        self.timestamp = try container.decode(Int64.self, forKey: .timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(createDate, forKey: .createDate)
        try container.encodeIfPresent(modifyDate, forKey: .modifyDate)
        try container.encode(md5, forKey: .md5)
        try container.encode(userId, forKey: .userId)
        try container.encode(tenantId, forKey: .tenantId)
        try container.encode(appId, forKey: .appId)
        try container.encode(appType, forKey: .appType)
        try container.encode(tag, forKey: .tag)
        try container.encode(primitiveAPI, forKey: .primitiveAPI)
        try container.encode(timestamp, forKey: .timestamp)
    }

    var description: String {
        var result: String = ""
        result += "("
        result += "path: \(path),"
        result += " size: \(size),"
        result += " createDate: \(createDate ?? 0),"
        result += " modifyDate: \(modifyDate ?? 0),"
        result += " md5: \(md5),"
        result += " userId: \(userId),"
        result += " tenantId: \(tenantId),"
        result += " appId: \(appId),"
        result += " appType: \(appType),"
        result += " tag: \(tag),"
        result += " primitiveAPI: \(primitiveAPI),"
        result += " timestamp: \(timestamp)"
        result += ")"
        return result
    }
}

/// FileSystem Log 挂载设置清理逻辑，只响应用户操作，不响应其他自动化逻辑
public final class FileSystemLogCleanTask: CleanTask {
    public var name: String {
        return "openplatform.filesystem.cleantask"
    }

    public init() {}

    public func clean(config: CleanConfig, completion: @escaping Completion) {
        guard config.isUserTriggered else {
            completion(TaskResult(completed: true, costTime: 0, size: .bytes(0)))
            return
        }

        let start = Date().timeIntervalSince1970
        size(config: config) { result in
            let dirURL = URL(fileURLWithPath: FileSystemLog.cacheDir)
            var isDir = false
            do {
                if LSFileSystem.fileExists(filePath: FileSystemLog.cacheDir, isDirectory: &isDir), isDir {
                    try LSFileSystem.fileLog.removeItem(atPath: dirURL.path)
                }
            } catch {
                FileSystemLog.logger.error("clean file log failed", error: error)
            }

            let end = Date().timeIntervalSince1970
            let cost = Int((end - start) * 1000)

            FileSystemLog.logger.info("clean filelog", additionalData: ["cost": "\(cost)"])
            completion(TaskResult(completed: true, costTime: cost, sizes: result.sizes))
        }
    }

    public func size(config: CleanConfig, completion: @escaping Completion) {
        guard config.isUserTriggered else {
            completion(TaskResult(completed: true, costTime: 0, size: .bytes(0)))
            return
        }

        let start = Date().timeIntervalSince1970

        var logFileSizes: [TaskResult.Size] = []
        do {
            let dirPath = FileSystemLog.cacheDir
            let dirURL = URL(fileURLWithPath: dirPath)
            logFileSizes = try LSFileSystem.contentsOfDirectory(dirPath: dirPath)
                .filter({ $0.hasSuffix(FileSystemLog.logExtension) })
                .map({ dirURL.appendingPathComponent($0) })
                .map({ url in
                    let attributes = try LSFileSystem.attributesOfItem(atPath: url.path) as NSDictionary
                    return TaskResult.Size.bytes(Int(truncatingIfNeeded: attributes.fileSize()))
                })
        } catch {
            FileSystemLog.logger.error("calculate file log size failed", error: error)
        }

        let end = Date().timeIntervalSince1970
        let cost = Int((end - start) * 1000)

        FileSystemLog.logger.info("calculate file log cache size", additionalData: [
            "cost": "\(cost)",
            "fileSizes": "bytes: \(logFileSizes.cleanBytes), count: \(logFileSizes.cleanCount)"
        ])

        completion(TaskResult(completed: true, costTime: cost, sizes: logFileSizes))
    }
}
