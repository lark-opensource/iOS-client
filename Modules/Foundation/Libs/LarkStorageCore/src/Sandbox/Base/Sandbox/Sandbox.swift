//
//  SandboxType.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import LKCommonsLogging

public typealias FileAttributes = [FileAttributeKey: Any]

// MARK: - SandboxType

public enum FileHandleUsage {
    case reading
    case writing(shouldAppend: Bool)
    case updating
}

public protocol SandboxType: AnyObject {
    associatedtype RawPath: PathType

    typealias RawReader<D> = (_ path: RawPath) throws -> D
    typealias RawWriter<D> = (_ data: D) throws -> Void

    // MARK: Operations

    func fileExists(atPath path: RawPath, isDirectory: UnsafeMutablePointer<Bool>?) -> Bool

    func createFile(atPath path: RawPath, contents: Data?, attributes: FileAttributes?) throws

    func createDirectory(
        atPath path: RawPath,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: FileAttributes?
    ) throws

    func setAttributes(_ attributes: FileAttributes, atPath path: RawPath) throws

    func removeItem(atPath path: RawPath) throws

    func moveItem(atPath srcPath: PathType, toPath dstPath: RawPath) throws

    func copyItem(atPath srcPath: PathType, toPath dstPath: RawPath) throws

    func displayName(atPath path: RawPath) -> String

    func attributesOfItem(atPath path: RawPath) throws -> FileAttributes

    func attributesOfFileSystem(forPath path: RawPath) throws -> FileAttributes

    func contentsOfDirectory(atPath path: RawPath) throws -> [String]

    func subpathsOfDirectory(atPath path: RawPath) throws -> [String]

    // MARK: Read/Write

    func performReading<D: SBBaseReadable>(atPath path: RawPath, with context: SBReadingContext) throws -> D

    func performWriting<D: SBBaseWritable>(_ data: D, atPath path: RawPath, with context: SBWritingContext) throws

    // MARK: InputStream/OutputStream

    func inputStream(atPath path: RawPath) -> InputStream?
    func inputStream_v2(atPath path: RawPath) -> SBInputStream?

    func outputStream(atPath path: RawPath, append shouldAppend: Bool) -> OutputStream?
    func outputStream_v2(atPath path: RawPath, append shouldAppend: Bool) -> SBOutputStream?

    // MARK: FileHandle
    func fileHandle(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> FileHandle
    func fileHandle_v2(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> SBFileHandle
}

// MARK: - Log

let sandboxLogger = Logger.log(Space.self, category: "LarkStorage.Sandbox")

extension SandboxType {
    var log: Log { sandboxLogger }
}

// MARK: - Sandbox

/// A `SandboxType` class
public class Sandbox<RawPath: PathType>: SandboxType {
    public enum ForwardResponder {
        case manager(FileManager)
        case sandbox(Sandbox<RawPath>)
    }

    public func forwardResponder() -> ForwardResponder {
        fatalError("Abstract Method", file: #fileID, line: #line)
    }

    public func fileExists(atPath path: RawPath, isDirectory: UnsafeMutablePointer<Bool>?) -> Bool {
        switch forwardResponder() {
        case .manager(let fm):
            return track(.fileExists, atPath: path) {
                var b: ObjCBool = false
                let ret = fm.fileExists(atPath: path.absoluteString, isDirectory: &b)
                isDirectory?.pointee = b.boolValue
                return ret
            }
        case .sandbox(let sb):
            return sb.fileExists(atPath: path, isDirectory: isDirectory)
        }
    }

    public func createFile(atPath path: RawPath, contents: Data?, attributes: FileAttributes?) throws {
        switch forwardResponder() {
        case .manager(let fm):
            try track(.createFile, atPath: path) {
                let ret = fm.createFile(
                    atPath: path.absoluteString,
                    contents: contents,
                    attributes: attributes
                )
                if !ret {
                    throw SandboxError.createFailure(message: "create file failed at \(path.absoluteString)")
                }
            }
        case .sandbox(let sb):
            try sb.createFile(atPath: path, contents: contents, attributes: attributes)
        }
    }

    public func createDirectory(
        atPath path: RawPath,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: FileAttributes?
    ) throws {
        switch forwardResponder() {
        case .manager(let fm):
            try track(.createDirectory, atPath: path) {
                try fm.createDirectory(
                    atPath: path.absoluteString,
                    withIntermediateDirectories: createIntermediates,
                    attributes: attributes
                )
            }
        case .sandbox(let sb):
            try sb.createDirectory(
                atPath: path,
                withIntermediateDirectories: createIntermediates,
                attributes: attributes
            )
        }
    }

    public func removeItem(atPath path: RawPath) throws {
        switch forwardResponder() {
        case .manager(let fm):
            try track(.removeItem, atPath: path) {
                try fm.removeItem(atPath: path.absoluteString)
            }
        case .sandbox(let sb):
            try sb.removeItem(atPath: path)
        }
    }

    public func moveItem(atPath srcPath: PathType, toPath dstPath: RawPath) throws {
        switch forwardResponder() {
        case .manager(let fm):
            try track(.moveItem, atPath: dstPath) {
                log.info("moveItem from \(srcPath.absoluteString) to: \(dstPath.absoluteString)")
                try fm.moveItem(atPath: srcPath.absoluteString, toPath: dstPath.absoluteString)
            }
        case .sandbox(let sb):
            try sb.moveItem(atPath: srcPath, toPath: dstPath)
        }
    }

    public func copyItem(atPath srcPath: PathType, toPath dstPath: RawPath) throws {
        switch forwardResponder() {
        case .manager(let fm):
            try track(.copyItem, atPath: dstPath) {
                log.info("copy from \(srcPath.absoluteString) to: \(dstPath.absoluteString)")
                try fm.copyItem(atPath: srcPath.absoluteString, toPath: dstPath.absoluteString)
            }
        case .sandbox(let sb):
            try sb.copyItem(atPath: srcPath, toPath: dstPath)
        }
    }

    public func attributesOfItem(atPath path: RawPath) throws -> FileAttributes {
        switch forwardResponder() {
        case .manager(let fm):
            return try track(.attributes, atPath: path) {
                return try fm.attributesOfItem(atPath: path.absoluteString)
            }
        case .sandbox(let sb):
            return try sb.attributesOfItem(atPath: path)
        }
    }

    public func attributesOfFileSystem(forPath path: RawPath) throws -> FileAttributes {
        switch forwardResponder() {
        case .manager(let fm):
            return try track(.systemAttributes, atPath: path) {
                return try fm.attributesOfFileSystem(forPath: path.absoluteString)
            }
        case .sandbox(let sb):
            return try sb.attributesOfFileSystem(forPath: path)
        }
    }

    public func displayName(atPath path: RawPath) -> String {
        switch forwardResponder() {
        case .manager(let fm):
            return track(.displayName, atPath: path) {
                return fm.displayName(atPath: path.absoluteString)
            }
        case .sandbox(let sb):
            return sb.displayName(atPath: path)
        }
    }

    public func contentsOfDirectory(atPath path: RawPath) throws -> [String] {
        switch forwardResponder() {
        case .manager(let fm):
            return try track(.directoryContents, atPath: path) {
                try fm.contentsOfDirectory(atPath: path.absoluteString)
            }
        case .sandbox(let sb):
            return try sb.contentsOfDirectory(atPath: path)
        }
    }

    public func subpathsOfDirectory(atPath path: RawPath) throws -> [String] {
        switch forwardResponder() {
        case .manager(let fm):
            return try track(.directorySubpaths, atPath: path) {
                try fm.subpathsOfDirectory(atPath: path.absoluteString)
            }
        case .sandbox(let sb):
            return try sb.subpathsOfDirectory(atPath: path)
        }
    }

    public func performReading<D: SBBaseReadable>(
        atPath path: RawPath,
        with context: SBReadingContext
    ) throws -> D {
        switch forwardResponder() {
        case .manager:
            return try track(.performReading, atPath: path) {
                guard let PathReadable = D.self as? SBPathReadable.Type else {
                    #if DEBUG || ALPHA
                    fatalError("unexpected")
                    #else
                    throw SandboxError.performReadingUnexpected(message: "path: \(path.absoluteString), type: \(type(of: D.self))")
                    #endif
                }
                let data = try PathReadable.sb_read(from: path.absoluteString, with: context)
                guard let ret = data as? D else {
                    #if DEBUG || ALPHA
                    fatalError("unexpected")
                    #else
                    throw SandboxError.performReadingUnexpected(message: "path: \(path.absoluteString), type: \(type(of: D.self))")
                    #endif
                }
                return ret
            }
        case .sandbox(let sb):
            return try sb.performReading(atPath: path, with: context)
        }
    }

    public func performWriting<D: SBBaseWritable>(
        _ data: D,
        atPath path: RawPath,
        with context: SBWritingContext
    ) throws {
        switch forwardResponder() {
        case .manager:
            try track(.performWriting, atPath: path) {
                guard let pathWritableData = data as? SBPathWritable else {
                    #if DEBUG || ALPHA
                    fatalError("unexpected")
                    #else
                    throw SandboxError.performWritingUnexpected(message: "path: \(path.absoluteString), type: \(type(of: D.self))")
                    #endif
                }
                return try pathWritableData.sb_write(to: path.absoluteString, with: context)
            }
        case .sandbox(let sb):
            try sb.performWriting(data, atPath: path, with: context)
        }
    }

    public func inputStream(atPath path: RawPath) -> InputStream? {
        switch forwardResponder() {
        case .manager:
            return track(.inputStream, atPath: path) {
                return InputStream(fileAtPath: path.absoluteString)
            }
        case .sandbox(let sb):
            return sb.inputStream(atPath: path)
        }
    }

    public func inputStream_v2(atPath path: RawPath) -> SBInputStream? {
        switch forwardResponder() {
        case .manager:
            return track(.inputStream, atPath: path) {
                return InputStream(fileAtPath: path.absoluteString)
            }
        case .sandbox(let sb):
            return sb.inputStream_v2(atPath: path)
        }
    }

    public func outputStream(atPath path: RawPath, append shouldAppend: Bool) -> OutputStream? {
        switch forwardResponder() {
        case .manager:
            return track(.outputStream, atPath: path) {
                return OutputStream(toFileAtPath: path.absoluteString, append: shouldAppend)
            }
        case .sandbox(let sb):
            return sb.outputStream(atPath: path, append: shouldAppend)
        }
    }

    public func outputStream_v2(atPath path: RawPath, append shouldAppend: Bool) -> SBOutputStream? {
        switch forwardResponder() {
        case .manager:
            return track(.outputStream, atPath: path) {
                return OutputStream(toFileAtPath: path.absoluteString, append: shouldAppend)
            }
        case .sandbox(let sb):
            return sb.outputStream_v2(atPath: path, append: shouldAppend)
        }
    }

    public func fileHandle(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> FileHandle {
        switch forwardResponder() {
        case .manager:
            return try track(.fileHandle, atPath: path) {
                let pathUrl = path.url
                switch usage {
                case .reading:
                    return try SBUtils.decryptedFileHandle(forReadingFrom: pathUrl)
                case .writing:
                    SBUtils.decryptInPlaceIfNeeded(pathUrl)
                    return try FileHandle(forWritingTo: pathUrl)
                case .updating:
                    SBUtils.decryptInPlaceIfNeeded(pathUrl)
                    return try FileHandle(forUpdating: pathUrl)
                }
            }
        case .sandbox(let sb):
            return try sb.fileHandle(atPath: path, forUsage: usage)
        }
    }

    public func fileHandle_v2(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> SBFileHandle {
        switch forwardResponder() {
        case .manager:
            return try track(.fileHandle, atPath: path) {
                /// 本实现是 **非加密场景** 的默认实现，说明如下：
                /// - 对于 reading，使用 SBCipher 提供的流式解密能力，避免明文落盘；
                /// - 对于 updating/writing，使用 SBCipher 提供的 path 解密能力，会导致明文解密（符合预期），
                ///   即如果目标文件是被加密过的，先对文件进行原地解密，然后再返回 `FileHandle`，
                ///   避免往加密文件中追加明文数据。
                let pathUrl = path.url
                switch usage {
                case .reading:
                    if let cipher = SBCipherManager.shared.cipher(for: .default) {
                        return try cipher.fileHandle(atPath: path.absoluteString, forUsage: .reading)
                    } else {
                        return try FileHandle(forReadingFrom: path.url).sb
                    }
                case .writing:
                    SBUtils.decryptInPlaceIfNeeded(pathUrl)
                    return try FileHandle(forWritingTo: pathUrl).sb
                case .updating:
                    SBUtils.decryptInPlaceIfNeeded(pathUrl)
                    return try FileHandle(forUpdating: pathUrl).sb
                }
            }
        case .sandbox(let sb):
            return try sb.fileHandle_v2(atPath: path, forUsage: usage)
        }
    }

    public func setAttributes(_ attributes: FileAttributes, atPath path: RawPath) throws {
        switch forwardResponder() {
        case .manager(let fm):
            try track(.setAttributes, atPath: path) {
                try fm.setAttributes(attributes, ofItemAtPath: path.absoluteString)
            }
        case .sandbox(let sb):
            try sb.setAttributes(attributes, atPath: path)
        }
    }

}

extension SBUtils {
    /// 在一些批量操作场景，可能会产生大量日志/埋点，暴露开关允许临时关闭
    static var disableLogTrack: Bool {
        get {
            return (Thread.current.threadDictionary["lark_storage.sandbox.disable_log_track"] as? Bool) ?? false
        }
        set {
            Thread.current.threadDictionary["lark_storage.sandbox.disable_log_track"] = newValue
        }
    }
}

extension Sandbox {
    // track and log
    internal func track<T>(
        _ action: SandboxTracker.Operation,
        atPath path: RawPath,
        block: () throws -> T
    ) rethrows -> T {
        let ret: T
        do {
            if SBUtils.disableLogTrack {
                ret = try block()
            } else {
                ret = try SandboxTracker.track(action, path: path, block: block)
                log.info("perform \(action) atPath \(path.absoluteString)")
            }
        } catch {
            log.error("perform \(action) atPath \(path.absoluteString) failed: \(error)")
            if error is SandboxError {
                throw error
            } else {
                throw SandboxError.system(action: action, underlying: error)
            }
        }
        return ret
    }
}
