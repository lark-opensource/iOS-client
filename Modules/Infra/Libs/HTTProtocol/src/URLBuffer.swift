//
//  URLBuffer.swift
//  HTTProtocol
//
//  Created by SolaWing on 2023/4/18.
//

import Foundation

// swiftlint:disable missing_docs

/// 主要用于保存完整的数据，如果太大且放弃缓存。
/// 实现Client需要这个结构来缓存data
public final class HTTProtocolBuffer {
    // 最大允许的body长度, 太大的数据不进行缓存
    // 使用Int.max代表无限缓存
    // 如果小于内存缓存大小，只有内存缓存
    public let maxLength: Int
    enum MemoryLimitedData {
        case memory(NSMutableData)
        case file(IOHandle, URL)
    }
    private var data: MemoryLimitedData

    // 内存缓存的Buffer数据大小，太大的数据可能导致更高的内存占用，因此需要进行限制并缓存到磁盘
    static let memoryCacheLength = 128 << 10
    static public let defaultMaxDiskLength = 64 << 20
    enum BufferError: Error {
        case unknown
        case overflow // extend max length
    }
    public convenience init(
        response: URLResponse, policy: URLCache.StoragePolicy,
        maxDiskLength: Int = HTTProtocolBuffer.defaultMaxDiskLength
    ) throws {
        var length: Int = Self.memoryCacheLength
        let maxLength = max(maxDiskLength, Self.memoryCacheLength)
        if
            let httpResponse = response as? HTTPURLResponse,
            let contentLengthString = httpResponse.headerString(field: "Content-Length"),
            let contentLength = Int(contentLengthString), contentLength > 0
        {
            if contentLength > maxLength { throw BufferError.overflow } // 太大的数据不进行缓存
            length = contentLength
        }
        try self.init(expect: length, maxDiskLength: maxLength)
    }
    /// Parameters:
    /// - length: guess length
    /// - maxDiskLength: max length in disk, 0 to memory only
    public init(expect length: Int, maxDiskLength: Int) throws {
        self.maxLength = maxDiskLength
        if length > Self.memoryCacheLength {
            let v = try Self.makeFileHandle()
            data = .file(v.0, v.1)
        } else {
            guard let v = NSMutableData(capacity: length) else {
                assertionFailure("create NSMutableData shouldn't fail!")
                throw BufferError.unknown
            }
            data = .memory(v)
        }
    }
    /// 调用方注意thread safe
    public func append(data: Data) throws {
        switch self.data {
        case .memory(let v):
            let length = v.length + data.count
            if length > Self.memoryCacheLength {
                if length > maxLength { throw BufferError.overflow }
                // upgrade to fileHandle case
                let handle = try Self.makeFileHandle()
                try handle.0.write(data: v as Data)
                try handle.0.write(data: data)
                self.data = .file(handle.0, handle.1)
            } else {
                v.append(data)
            }
        case .file(let handle, _):
            if try Int(handle.offset()) + data.count > maxLength {
                throw BufferError.overflow
            }
            try handle.write(data: data)
        }
    }
    public var length: Int {
        switch self.data {
        case .memory(let v): return v.length
        case .file(let handle, _): return (try? Int(handle.offset())) ?? 0
        }
    }
    public func asData() -> Data {
        switch self.data {
        case .memory(let v):
            return v as Data
        case .file(let handle, _):
            do {
                try handle.seek(toOffset: 0)
                return try handle.readToEnd() ?? Data()
            } catch {
                return Data()
            }
        }
    }
    public func asURL() throws -> URL {
        switch self.data {
        case .memory(let v):
            let handle = try Self.makeFileHandle()
            try handle.0.write(data: v as Data)
            try handle.0.close()
            return handle.1
        case let .file(handle, url):
            try handle.synchronize()
            return url
        }
    }
    static private func makeFileHandle() throws -> (IOHandle, URL) {
        // lint:disable lark_storage_check - 存缓存到 tmp/ 用于上下文同步
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + ".rustHTTPCacheDownload")
        FileManager.default.createFile(atPath: tmp.path, contents: nil, attributes: nil)
        let handler = try FileHandle(forUpdating: tmp)
        // lint:enable lark_storage_check
        if #available(iOS 13.4, *) {
            return (handler, tmp)
        } else {
            return (OldFileHandle(value: handler), tmp)
        }
    }
}

protocol IOHandle {
    func write(data: Data) throws
    func offset() throws -> UInt64
    func seek(toOffset offset: UInt64) throws
    func readToEnd() throws -> Data?
    func close() throws
    func synchronize() throws
}

@available(iOS 13.4, *)
@nonobjc extension FileHandle: IOHandle {
    func write(data: Data) throws {
        try self.write(contentsOf: data)
    }
}
private struct OldFileHandle: IOHandle {
    var value: FileHandle
    func write(data: Data) throws {
        let error = http_objc_catch { value.write(data) }
        if let error { throw error }
    }
    func offset() throws -> UInt64 {
        var out: UInt64 = 0
        let error = http_objc_catch { out = value.offsetInFile }
        if let error { throw error }
        return out
    }
    func seek(toOffset offset: UInt64) throws {
        let error = http_objc_catch { value.seek(toFileOffset: offset) }
        if let error { throw error }
    }
    func readToEnd() throws -> Data? {
        var out: Data?
        let error = http_objc_catch { out = value.readDataToEndOfFile() }
        if let error { throw error }
        return out
    }
    func close() throws {
        let error = http_objc_catch { value.closeFile() }
        if let error { throw error }
    }
    func synchronize() throws {
        let error = http_objc_catch { value.synchronizeFile() }
        if let error { throw error }
    }
}

// swiftlint:enable missing_docs
