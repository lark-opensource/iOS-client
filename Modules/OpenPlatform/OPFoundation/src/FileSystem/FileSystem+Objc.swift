//
//  FileSystem+Objc.swift
//  TTMicroApp
//
//  Created by Meng on 2021/8/25.
//

import Foundation
import ECOProbe
import ECOInfra

/// FileSystem.Context
@objcMembers
public final class OPFileSystemContext: NSObject {
    fileprivate let fsContext: FileSystem.Context

    public var trace: OPTrace {
        return fsContext.trace
    }

    /// init FileSystem.Context with uniqueId, trace
    ///
    /// default tag is unknown
    /// default isAuxiliary is false
    /// - Parameters:
    ///   - uniqueId: uniqueId
    ///   - trace: trace
    public init(uniqueId: OPAppUniqueID, trace: OPTrace?) {
        self.fsContext = FileSystem.Context(uniqueId: uniqueId, trace: trace)
    }

    /// init FileSystem.Context with uniqueId, trace, tag
    ///
    /// default isAuxiliary is false
    ///
    /// - Parameters:
    ///   - uniqueId: uniqueId
    ///   - trace: trace
    ///   - tag: tag
    public init(uniqueId: OPAppUniqueID, trace: OPTrace?, tag: String) {
        self.fsContext = FileSystem.Context(uniqueId: uniqueId, trace: trace, tag: tag)
    }

    /// init FileSystem.Context with uniqueId, trace, tag, isAuxiliary
    /// - Parameters:
    ///   - uniqueId: uniqueId
    ///   - trace: trace
    ///   - tag: tag
    ///   - isAuxiliary: isAuxiliary
    public init(uniqueId: OPAppUniqueID, trace: OPTrace?, tag: String, isAuxiliary: Bool) {
        self.fsContext = FileSystem.Context(uniqueId: uniqueId, trace: trace, tag: tag, isAuxiliary: isAuxiliary)
    }
}

/// FileObject
@objcMembers
public final class OPFileObject: NSObject {
    /// FileObject.rawValue
    public var rawValue: String {
        return fsFile.rawValue
    }

    fileprivate let fsFile: FileObject

    public init?(rawValue: String) {
        guard let safeRawValue = OPUnsafeObject(rawValue) else {
            return nil
        }
        guard let file = try? FileObject(rawValue: safeRawValue) else {
            return nil
        }
        self.fsFile = file
    }

    private init(fsFile: FileObject) {
        self.fsFile = fsFile
    }

    /// FileObject.lastPathComponent
    public var lastPathComponent: String {
        return fsFile.lastPathComponent
    }

    /// FileObject.deletingLastPathComponent
    public var deletingLastPathComponent: OPFileObject {
        return OPFileObject(fsFile: fsFile.deletingLastPathComponent)
    }

    /// FileObject.pathExtension
    public var pathExtension: String {
        return fsFile.pathExtension
    }

    /// FileObject.appendingPathComponent
    public func appendingPathComponent(_ component: String) -> OPFileObject {
        return OPFileObject(fsFile: fsFile.appendingPathComponent(component))
    }

    /// FileObject.isInUserDir
    public var isInUserDir: Bool {
        return fsFile.isInUserDir
    }

    /// FileObject.isInTempDir
    public var isInTempDir: Bool {
        return fsFile.isInTempDir
    }

    /// FileObject.isValidTTFile
    public var isValidTTFile: Bool {
        return fsFile.isValidTTFile()
    }

    /// FileObject.isValidSandboxFilePath
    public var isValidSandboxFilePath: Bool {
        return fsFile.isValidSandboxFilePath()
    }

    /// FileObject.isValidPackageFile
    public var isValidPackageFile: Bool {
        return fsFile.isValidPackageFile()
    }

    /// FileObject.generateRandomTTFile
    public class func generateRandomTTFile(_ type: BDPFolderPathType, fileExtension: String?) -> OPFileObject {
        return OPFileObject(fsFile: FileObject.generateRandomTTFile(type: type, fileExtension: fileExtension))
    }

    /// FileObject.generateSpecificTTFile
    public class func generateSpecificTTFile(_ type: BDPFolderPathType, pathComponment: String) -> OPFileObject {
        let unsafePathComponment = OPUnsafeObject(pathComponment)
        return OPFileObject(fsFile: FileObject.generateSpecificTTFile(type: type, pathComponment: unsafePathComponment ?? ""))
    }
}

/// OPFileSystemUtils
///
/// 用于 objc 的 OPFileSystemUtils 接口
@available(swift, obsoleted: 1.0)
@objcMembers
public final class OPFileSystemUtils: NSObject {
    /// 标准 API 迁移开关判断
    /// - Parameter feature: 迁移的 feature
    /// - Returns: 是否打开
    public class func isEnableStandardFeature(_ feature: String) -> Bool {
        return FileSystemUtils.isEnableStandardFeature(feature)
    }

    public class func encodeFileData(_ data: Data, encoding: String) -> String? {
        guard let fsEncoding = FileSystemEncoding(rawValue: encoding) else {
            return nil
        }
        return FileSystemUtils.encodeFileData(data, encoding: fsEncoding)
    }

    public class func decodeFileDataString(_ dataString: String, encoding: String) -> Data? {
        guard let fsEncoding = FileSystemEncoding(rawValue: encoding) else {
            return nil
        }
        return FileSystemUtils.decodeFileDataString(dataString, encoding: fsEncoding)
    }

    public class func generateRandomPrivateTmpPath(with sandbox: BDPMinimalSandboxProtocol, pathExtension: String?) -> String? {
        return FileSystemUtils.generateRandomPrivateTmpPath(with: sandbox, pathExtension: pathExtension)
    }
}

/// OPFileSystemError
///
/// 用于 objc 的 OPFileSystemError 接口
@available(swift, obsoleted: 1.0)
@objcMembers
public final class OPFileSystemError: NSObject {
    public class var SRC_FILE_RAW_VALUE_KEY: String {
        return FileSystemError.SRC_FILE_RAW_VALUE_KEY
    }

    public class var DEST_FILE_RAW_VALUE_KEY: String {
        return FileSystemError.DEST_FILE_RAW_VALUE_KEY
    }

    public class var INVALID_PARAM_KEY: String {
        return FileSystemError.INVALID_PARAM_KEY
    }

    /// 判断是否是 unknown error
    public class func matchUnknownError(_ error: NSError) -> Bool {
        guard let safeError = OPUnsafeObject(error) else {
            return false
        }
        let allCodes = FileSystemErrorCode.allCases.map({ $0.rawValue })
        return safeError.domain != FileSystemError.errorDomain || !allCodes.contains(safeError.code)
    }

    /// 判断是否是 system error (FileSystemError.system)
    public class func matchSystemError(_ error: NSError) -> Bool {
        guard let safeError = OPUnsafeObject(error) else {
            return false
        }
        return safeError.domain == FileSystemError.errorDomain && safeError.code == FileSystemErrorCode.system.rawValue
    }

    /// 判断是否是 biz error
    public class func matchAllBizError(_ error: NSError) -> Bool {
        guard let safeError = OPUnsafeObject(error) else {
            return false
        }
        /// 判断一级 domain & code
        guard safeError.domain == FileSystemError.errorDomain && safeError.code == FileSystemErrorCode.biz.rawValue else {
            return false
        }
        /// 获取二级 bizError
        guard let bizError = safeError.userInfo[NSUnderlyingErrorKey] as? NSError else {
            return false
        }
        /// 判断二级 bizError domain & code
        let allBizCodes = FileSystemBizErrorCode.allCases.map({ $0.rawValue })
        return bizError.domain == FileSystemError.BizError.errorDomain && allBizCodes.contains(bizError.code)
    }

    /// 判断是否是 biz error (FileSystemError.BizError)
    public class func matchBizError(_ bizCodes: [Int], error: NSError) -> Bool {
        guard let safeError = OPUnsafeObject(error) else {
            return false
        }
        /// 判断一级 domain & code
        guard safeError.domain == FileSystemError.errorDomain && safeError.code == FileSystemErrorCode.biz.rawValue else {
            return false
        }
        /// 获取二级 bizError
        guard let bizError = safeError.userInfo[NSUnderlyingErrorKey] as? NSError else {
            return false
        }
        /// 判断二级 bizError domain & code
        let allBizCodes = FileSystemBizErrorCode.allCases.map({ $0.rawValue })
        guard bizError.domain == FileSystemError.BizError.errorDomain && allBizCodes.contains(bizError.code) else {
            return false
        }
        /// 判断所有 biz code 都是 FileSystemBizErrorCode
        guard bizCodes.allSatisfy({ allBizCodes.contains($0) }) else {
            return false
        }
        /// 判断 bizError code 是否在传入 code 范围
        return bizCodes.contains(bizError.code)
    }

    /// 判断是否是 filesystem error
    public class func matchFileSystemError(_ fileSystemCodes: [Int], error: NSError) -> Bool {
        /// 判断一级 domain & code
        let allFileSystemCodes = FileSystemErrorCode.allCases.map({ $0.rawValue })
        guard error.domain == FileSystemError.errorDomain && allFileSystemCodes.contains(error.code) else {
            return false
        }

        /// 判断所有 filesystem code 都是 FileSystemErrorCode
        guard fileSystemCodes.allSatisfy({ allFileSystemCodes.contains($0) }) else {
            return false
        }

        /// 判断 error code 是否在传入 code 范围
        return fileSystemCodes.contains(error.code)
    }

    /// 判断是否是 filesystem error
    public class func matchAllFileSystemError(_ error: NSError) -> Bool {
        let allFileSystemCodes = FileSystemErrorCode.allCases.map({ $0.rawValue })
        return error.domain == FileSystemError.errorDomain && allFileSystemCodes.contains(error.code)
    }
}

/// OPFileSystem
///
/// 用于 objc 的 FileSystem 接口
@available(swift, obsoleted: 1.0)
@objcMembers
public final class OPFileSystem: NSObject {
    /// FileSystem.fileExist
    public class func fileExist(_ file: OPFileObject, context: OPFileSystemContext) throws -> NSNumber {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        let exists = try FileSystem.fileExist(safeFile.fsFile, context: safeContext.fsContext)
        return NSNumber(booleanLiteral: exists)
    }

    /// FileSystem.isDirectory
    public class func isDirectory(_ file: OPFileObject, context: OPFileSystemContext) throws -> NSNumber {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        let isDir = try FileSystem.isDirectory(safeFile.fsFile, context: safeContext.fsContext)
        return NSNumber(booleanLiteral: isDir)
    }

    /// FileSystem.listContents
    public class func listContents(_ file: OPFileObject, context: OPFileSystemContext) throws -> [String] {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        return try FileSystem.listContents(safeFile.fsFile, context: safeContext.fsContext)
    }

    /// FileSystem.attributesOfFile
    public class func attributesOfFile(_ file: OPFileObject, context: OPFileSystemContext) throws -> [FileAttributeKey: Any] {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        return try FileSystem.attributesOfFile(safeFile.fsFile, context: safeContext.fsContext)
    }

    /// FileSystem.readFile
    public class func readFile(_ file: OPFileObject, position: Int64, length: Int64, threshold: Int64, context: OPFileSystemContext) throws -> Data {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        return try FileSystem.readFile(
            safeFile.fsFile, position: position, length: length, threshold: threshold, context: safeContext.fsContext
        )
    }

    /// FileSystem.readFile
    public class func readFile(_ file: OPFileObject, context: OPFileSystemContext) throws -> Data {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        return try FileSystem.readFile(
            safeFile.fsFile, position: nil, length: nil, threshold: nil, context: safeContext.fsContext
        )
    }

    /// FileSystem.removeFile
    public class func removeFile(_ file: OPFileObject, context: OPFileSystemContext) throws {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        try FileSystem.removeFile(safeFile.fsFile, context: safeContext.fsContext)
    }

    /// FileSystem.moveFile
    public class func moveFile(src: OPFileObject, dest: OPFileObject, context: OPFileSystemContext) throws {
        guard let safeSrc = OPUnsafeObject(src),
              let safeDest = OPUnsafeObject(dest),
              let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        try FileSystem.moveFile(src: safeSrc.fsFile, dest: safeDest.fsFile, context: safeContext.fsContext)
    }

    /// FileSystem.copyFile
    public class func copyFile(src: OPFileObject, dest: OPFileObject, context: OPFileSystemContext) throws {
        guard let safeSrc = OPUnsafeObject(src),
              let safeDest = OPUnsafeObject(dest),
              let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        try FileSystem.copyFile(src: safeSrc.fsFile, dest: safeDest.fsFile, context: safeContext.fsContext)
    }

    /// FileSystem.writeFile
    public class func writeFile(_ file: OPFileObject, data: Data, context: OPFileSystemContext) throws {
        guard let safeFile = OPUnsafeObject(file),
              let safeData = OPUnsafeObject(data),
              let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        try FileSystem.writeFile(safeFile.fsFile, data: safeData, context: safeContext.fsContext)
    }

    /// FileSystem.createDirectory
    public class func createDirectory(
        _ file: OPFileObject, recursive: Bool, attributes: [FileAttributeKey: Any]?, context: OPFileSystemContext
    ) throws {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        try FileSystem.createDirectory(safeFile.fsFile, recursive: recursive, attributes: attributes ?? [:], context: safeContext.fsContext)
    }

    /// FileSystem.removeDirectory
    public class func removeDirectory(_ file: OPFileObject, recursive: Bool, context: OPFileSystemContext) throws {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        try FileSystem.removeDirectory(safeFile.fsFile, recursive: recursive, context: safeContext.fsContext)
    }

    /// FileSystem.canRead
    public class func canRead(_ file: OPFileObject, context: OPFileSystemContext) throws -> NSNumber {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        let result = try FileSystem.canRead(safeFile.fsFile, context: safeContext.fsContext)
        return NSNumber(booleanLiteral: result)
    }

    /// FileSystem.canWrite
    public static func canWrite(_ file: OPFileObject, isRemove: Bool, context: OPFileSystemContext) throws -> NSNumber {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        let result = try FileSystem.canWrite(safeFile.fsFile, isRemove: isRemove, context: safeContext.fsContext)
        return NSNumber(booleanLiteral: result)
    }

    /// FileSystem.isOverSizeLimit
    public static func isOverSizeLimit(_ src: OPFileObject, dest: OPFileObject, context: OPFileSystemContext) throws -> NSNumber {
        guard let safeSrc = OPUnsafeObject(src),
              let safeDest = OPUnsafeObject(dest),
              let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        let result = try FileSystem.isOverSizeLimit(src: safeSrc.fsFile, dest: safeDest.fsFile, context: safeContext.fsContext)
        return NSNumber(booleanLiteral: result)
    }

    /// FileSystem.isOverSizeLimit
    public static func isOverSizeLimit(_ file: OPFileObject, data: Data, context: OPFileSystemContext) throws -> NSNumber {
        guard let safeFile = OPUnsafeObject(file),
              let safeData = OPUnsafeObject(data),
              let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        let result = try FileSystem.isOverSizeLimit(safeFile.fsFile, data: safeData, context: safeContext.fsContext)
        return NSNumber(booleanLiteral: result)
    }
}

/// OPFileSystemCompatible
///
/// 用于 objc 的 OPFileSystemCompatible 接口
@available(swift, obsoleted: 1.0)
@objcMembers
public final class OPFileSystemCompatible: NSObject {
    /// FileSystemCompatible.getSystemFile
    public static func getSystemFile(from file: OPFileObject, context: OPFileSystemContext) throws -> String {
        guard let safeFile = OPUnsafeObject(file), let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        return try FileSystemCompatible.getSystemFile(from: safeFile.fsFile, context: safeContext.fsContext)
    }

    /// FileSystemCompatible.copySystemFile
    public static func copySystemFile(_ systemFilePath: String, to file: OPFileObject, context: OPFileSystemContext) throws {
        guard let safeSystemFile = OPUnsafeObject(systemFilePath),
              let safeFile = OPUnsafeObject(file),
              let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        try FileSystemCompatible.copySystemFile(safeSystemFile, to: safeFile.fsFile, context: safeContext.fsContext)
    }

    /// FileSystemCompatible.moveSystemFile
    public static func moveSystemFile(_ systemFilePath: String, to file: OPFileObject, context: OPFileSystemContext) throws {
        guard let safeSystemFile = OPUnsafeObject(systemFilePath),
              let safeFile = OPUnsafeObject(file),
              let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        try FileSystemCompatible.moveSystemFile(safeSystemFile, to: safeFile.fsFile, context: safeContext.fsContext)
    }

    /// FileSystemCompatible.moveSystemFile
    public static func writeSystemData(_ data: Data, to file: OPFileObject, context: OPFileSystemContext) throws {
        guard let safeData = OPUnsafeObject(data),
              let safeFile = OPUnsafeObject(file),
              let safeContext = OPUnsafeObject(context) else {
            throw FileSystemError.biz(.resolveParamsFromObjcFailed)
        }
        try FileSystemCompatible.writeSystemData(safeData, to: safeFile.fsFile, context: safeContext.fsContext)
    }
}
