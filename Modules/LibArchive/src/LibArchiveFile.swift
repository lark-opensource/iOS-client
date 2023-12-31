//
//  LibArchiveFile.swift
//  LibArchiveExample
//
//  Created by ZhangYuanping on 2021/9/12.
//  


import Foundation

public final class LibArchiveFile {
    
    private enum Source {
        case path(String)
        case data(Data)
    }
    
    public private(set) var isEncrypted: Bool = false
    public private(set) var format: ArchiveFormat = .unknown
    
    private var archive: OpaquePointer?
    private let source: Source
    private var passcode: String?
        
    public init(path: String) throws {
        self.source = .path(path)
        try setupArchive()
        parseBasicInfo()
    }
    
    public init(data: Data) throws {
        self.source = .data(data)
        try setupArchive()
        parseBasicInfo()
    }
    
    deinit {
        ArchiveLogger.shared.info("LibArchiveFile deinit")
        guard let archive = archive else { return }
        archive_read_close(archive)
        archive_read_free(archive)
    }
    
    /// 因为 archive 读取相当于一个指针，比如执行了一次 read_next_header 后，
    /// 指针不能重新回到头部，当你又想有新的操作时，它会继续往下读
    /// 所以这个方法在每次执行操作前需调用，相当于重置的功能。
    private func setupArchive() throws {
        if let archive = archive {
            archive_read_close(archive)
            archive_read_free(archive)
        }
        
        archive = archive_read_new()
        archive_read_support_filter_all(archive)
        archive_read_support_format_all(archive)
        
        let addPassphraseAction = {
            // 设置密码必须是在 archive 的 new 阶段，即 read open 前
            if let passcode = self.passcode, let passcodeCStr = passcode.cString(using: .utf8) {
                let r = archive_read_add_passphrase(self.archive, passcodeCStr)
                if r != ARCHIVE_OK {
                    throw LibArchiveError.addPassCodeFail(message: self.getErrorMessage(symbol: "archive_read_add_passphrase"))
                }
            }
        }

        switch source {
        case .path(let string):
            
            guard var filePath = string.cString(using: .utf8) else {
                ArchiveLogger.shared.error("url.path.cString nil")
                throw LibArchiveError.pathCStringFail
            }
            
            try addPassphraseAction()
            
            let r = archive_read_open_filename(archive, &filePath, 10240)
            
            if r != ARCHIVE_OK {
                throw LibArchiveError.readOpenFileFail(message: getErrorMessage(symbol: "archive_read_open_filename"))
            }
        case .data(let data):
            
            guard !(data.isEmpty) else {
                throw LibArchiveError.emptyDataContent
            }
            
            try addPassphraseAction()
            
            let nsData = data as NSData
            let r = archive_read_open_memory(archive, nsData.bytes, nsData.length)
            
            if r != ARCHIVE_OK {
                throw LibArchiveError.readOpenFileFail(message: getErrorMessage(symbol: "archive_read_open_memory"))
            }
        }
    }
    
    /// 解析出压缩文件目录信息
    public func parseFileList() throws -> [LibArchiveEntry] {
        try setupArchive()
        var entry = archive_entry_new()
        var results = [LibArchiveEntry]()
        var archiveError: LibArchiveError?
        while archive_read_next_header(self.archive, &entry) == ARCHIVE_OK {
            let type = archive_entry_filetype(entry)
            if let cStr = archive_entry_pathname(entry),
               let pathName = getPathName(cStr: cStr),
               let fileType = LibArchiveEntry.EntryType(rawValue: Int(type)) {
                let size = archive_entry_size(entry)
                let archiveEntry = LibArchiveEntry(type: fileType, path: pathName, size: UInt64(size))
                results.append(archiveEntry)
            } else {
                // TODO: yuanping 处理部分失败的情况
                if let error = archive_error_string(self.archive) {
                    let errorStr = String(cString: error)
                    archiveError = .readHeaderFail(message: errorStr)
                    ArchiveLogger.shared.error("no archive pathname failed \(errorStr)")
                } else {
                    archiveError = .emptyPathName
                    
                }
            }
            archive_read_data_skip(self.archive)
        }
        
        return results
    }
    
    /// 全量解压文件到指定目录
    public func extract(toDir: URL, passcode: String? = nil) throws {
        self.passcode = passcode
        try setupArchive()
        
        let writeArchive = archive_write_disk_new()
        defer {
            archive_write_close(writeArchive)
            archive_write_free(writeArchive)
        }
        
        archive_write_disk_set_standard_lookup(writeArchive)
        
        var entry = archive_entry_new()
        while true {
            var rs = archive_read_next_header(self.archive, &entry)
            
            // 判断是否已经读取到文件末尾
            if rs == ARCHIVE_EOF {
                ArchiveLogger.shared.info("Extact Archive EOF")
                break
            }
            if rs != ARCHIVE_OK {
                let message = self.getErrorMessage(symbol: "read_next_header")
                throw LibArchiveError.readHeaderFail(message: message)
            }
            
            guard let cStr = archive_entry_pathname(entry),
                  let pathNameStr = getPathName(cStr: cStr) else {
                ArchiveLogger.shared.warn("archive_entry_pathname is null")
                continue
            }
            
            var dir = toDir
            dir.appendPathComponent(pathNameStr)
            
            // 指定解压的目录路径
            let path = dir.path.cString(using: .utf8)
            archive_entry_set_pathname(entry, path)
            
            rs = archive_write_header(writeArchive, entry)
            if rs != ARCHIVE_OK {
                let message = self.getErrorMessage(symbol: "write_header")
                throw LibArchiveError.writeHeaderFail(message: message)
            }
            
            // 解压写磁盘
            try copyDataToWriteArchive(writeArchive)
        }
    }
    
    
    /// 按需解压文件到指定目录
    /// - Parameters:
    ///   - entryName: 按需解压的文件（ArchiveEntry 的相对路径）
    ///   - toDir: 解压目录
    ///   - passcode: 密码
    ///   - completion: 解压结果
    public func extract(entryPath: String, toDir: URL, passcode: String? = nil) throws {
        self.passcode = passcode
        try setupArchive()
        let writeArchive = archive_write_disk_new()
        defer {
            archive_write_close(writeArchive)
            archive_write_free(writeArchive)
        }
        
        archive_write_disk_set_standard_lookup(writeArchive)
        
        var entry = archive_entry_new()
        while true {
            var rs = archive_read_next_header(archive, &entry)
            
            // 判断是否已经读取到文件末尾
            if rs == ARCHIVE_EOF {
                ArchiveLogger.shared.info("Extact Archive EOF")
                throw LibArchiveError.entryNotFound
            }
            if rs != ARCHIVE_OK {
                let message = getErrorMessage(symbol: "read_next_header")
                throw LibArchiveError.readHeaderFail(message: message)
            }
            
            guard let cStr = archive_entry_pathname(entry),
                  let pathNameStr = getPathName(cStr: cStr) else {
                continue
            }
            
            // 判断读取到的 entryPathName 是否与需要解压的 entryName 一致，一致则去解压
            guard pathNameStr == entryPath else { continue }
            
            // 构建解压目录，解压目录+entryPath
            var dir = toDir
            dir.appendPathComponent(pathNameStr)
            ArchiveLogger.shared.info("Extacting \(pathNameStr) to path: \(dir.path)")
            
            // 给 archive_entry 指定解压的目录路径
            let path = dir.path.cString(using: .utf8)
            archive_entry_set_pathname(entry, path)
            
            // 构建新的 archive header
            rs = archive_write_header(writeArchive, entry)
            
            if rs == ARCHIVE_OK {
                // 解压写磁盘
                try copyDataToWriteArchive(writeArchive)
            } else {
                let message = getErrorMessage(symbol: "write_header")
                throw LibArchiveError.writeHeaderFail(message: message)
            }
            break
        }
    }
    
    
    // MARK: - Private Function
    
    /// 读取压缩文件基本信息：format 和 是否加密
    private func parseBasicInfo() {
        var entry = archive_entry_new()
        if archive_read_next_header(archive, &entry) == ARCHIVE_OK {
            let format = ArchiveFormat(rawValue: archive_format(archive))
            let hasEncrypted = archive_read_has_encrypted_entries(archive)
            ArchiveLogger.shared.info("archive format: \(format), isEncrypted: \(hasEncrypted)")
            self.isEncrypted = hasEncrypted == 1
            self.format = format
        } else {
            guard let error = archive_error_string(archive) else { return }
            let errorStr = String(cString: error)
            // 如果错误信息里包含 encrypt 信息，则判断为加密。e.g 7z、文件名加密的 rar 只能通过 read header 的错误信息判断是否加密
            if errorStr.lowercased().contains("encrypt") {
                self.isEncrypted = true
            }
            ArchiveLogger.shared.error("parse base info error: \(errorStr)")
        }
    }
    
    /// 读取 Entry 数据并写数据到磁盘
    private func copyDataToWriteArchive(_ writeArchive: OpaquePointer?) throws {
        var buff: UnsafeRawPointer? = nil
        var size: size_t = 0
        var offset: la_int64_t = 0
                
        while true {
            let result = archive_read_data_block(archive, &buff, &size, &offset)
            if result == ARCHIVE_EOF {
                break
            }
            if result != ARCHIVE_OK {
                let message = getErrorMessage(symbol: "read_data_block")
                throw LibArchiveError.readDataBlockFail(message: message)
            }
            
            let writeResult = archive_write_data_block(writeArchive, buff, size, offset)
            if writeResult != ARCHIVE_OK {
                let message = getErrorMessage(symbol: "write_data_block")
                throw LibArchiveError.writeDataBlockFail(message: message)
            }
        }
    }
    
    @discardableResult
    private func getErrorMessage(symbol: String = "") -> String {
        if let error = archive_error_string(archive) {
            let message = ("\(symbol) failed: \(String(cString: error))")
            ArchiveLogger.shared.error("\(message)")
            return message
        } else {
            return "no error string"
        }
    }
    
    private func getPathName(cStr: UnsafePointer<CChar>) -> String? {
        // 先以 UTF-8 读取字符
        var pathName = String(utf8String: cStr)
        if pathName == nil {
            // 若为空，说明字符没有以 UTF-8 编码，尝试以 GBK 读取字符
            let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
            pathName = String(cString: cStr, encoding: encoding)
        }
        return pathName
    }
}

public extension LibArchiveFile {
    
    /// 是否是7zip格式
    func is7zFormat() -> Bool {
        if let archive = archive {
            let format = ArchiveFormat(rawValue: archive_format(archive))
            return format == .archive_7z
        }
        return false
    }
    
    /// 全量解压该7zip文件到指定目录
    /// - Parameters:
    ///   - toDir: 目标路径
    ///   - preserveDir: 是否保留压缩包内文件目录结构
    /// - Throws: 解压中可能出现异常
    func extract7z(toDir: URL, preserveDir: Bool = true) throws {
        
        if case .path(let path) = source {
            try LZMA7zExtractor.extract7zArchive(path: path, targetDir: toDir.path, preserveDir: preserveDir)
        }
    }
}

public enum LibArchiveError: Error, LocalizedError {
    case readOpenFileFail(message: String)
    case addPassCodeFail(message: String)
    case readHeaderFail(message: String)
    case readDataBlockFail(message: String)
    case writeDataBlockFail(message: String)
    case writeHeaderFail(message: String)
    case emptyPathName
    case emptyDataContent
    case entryNotFound
    case pathCStringFail
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .readOpenFileFail(let message), .readHeaderFail(let message), .readDataBlockFail(let message),
             .addPassCodeFail(let message),
             .writeDataBlockFail(let message), .writeHeaderFail(let message):
            return message
        case .emptyPathName:
            return "empty path name"
        case .emptyDataContent:
            return "empty data content"
        case .entryNotFound:
            return "entry Not Found"
        case .pathCStringFail:
            return "path to cString Fail"
        case .unknown:
            return "unknown"
        }
    }
}

public enum ArchiveFormat {
    case zip
    case rar4
    case rar5
    case archive_7z
    case tar
    case tar_ustar
    case xar
    case unknown
    
    public init(rawValue: Int32) {
        switch rawValue {
        case ARCHIVE_FORMAT_ZIP:
            self = .zip
        case ARCHIVE_FORMAT_RAR:
            self = .rar4
        case ARCHIVE_FORMAT_RAR_V5:
            self = .rar5
        case ARCHIVE_FORMAT_TAR:
            self = .tar
        case ARCHIVE_FORMAT_XAR:
            self = .xar
        case ARCHIVE_FORMAT_TAR_USTAR:
            self = .tar_ustar
        case ARCHIVE_FORMAT_7ZIP:
            self = .archive_7z
        default:
            self = .unknown
        }
    }
}
