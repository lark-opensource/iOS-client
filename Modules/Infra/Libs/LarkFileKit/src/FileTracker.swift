//
//  FileManagerTracker.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/9/27.
//

import Foundation

public enum FileManagerOperation: String {
    case fileRead
    case fileWrite
    case fileAttributeRead
    case fileAttributeWrite
    case fileChildren
    case fileEnumerate
    case fileExists
    case createFile
    case touch
    case createDirectory
    case deleteFile
    case moveFile
    case copyFile
    case fileHandle
    case inputStream
    case outputStream
    case archive
    case unarchive

    var shouldLogSize: Bool {
        switch self {
        case .fileRead, .fileWrite, .archive, .unarchive:
            return true
        default:
            return false
        }
    }
}

/// 文件操作监控信息格式
public struct FileTrackInfo {
    /// 文件路径
    public let path: Path
    /// 是否主线程
    public let isMainThread: Bool
    /// 文件读、写数据量
    public let size: UInt64?
    /// 操作类型
    public let operation: FileManagerOperation
    /// 耗时
    public let duration: TimeInterval
    /// 文件操作错误
    public let error: Error?
}

final class FileTracker {
    static var trackerEnable: Bool = true

    static func track<T>(_ path: Path, operation: FileManagerOperation, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result: T
        do {
            result = try block()
            let endTime = CFAbsoluteTimeGetCurrent()
            track(path, operation: operation, duration: endTime - startTime)
        } catch {
            let endTime = CFAbsoluteTimeGetCurrent()
            track(path, operation: operation, duration: endTime - startTime, error: error)
            throw error
        }
        return result
    }

    private static func track(_ path: Path,
                              operation: FileManagerOperation,
                              duration: TimeInterval,
                              error: Error? = nil) {
        // 暂时下掉文件操作日志上报功能
//        guard trackerEnable else {
//            return
//        }
//        let size: UInt64? = operation.shouldLogSize ? path.fileSize : nil
//
//        let info = FileTrackInfo(path: path,
//                                 isMainThread: Thread.current === Thread.main,
//                                 size: size,
//                                 operation: operation,
//                                 duration: duration,
//                                 error: error)
//
//        FileTrackInfoHandlerRegistry.handlers.forEach { $0.track(info: info) }
    }
}

/// 处理FileTrackInfo
public protocol FileTrackInfoHandler {
    /// 处理FileTrackInfo，外界实现上报等功能
    /// - Parameter info: file track info
    func track(info: FileTrackInfo)
}

/// FileTrackInfoHandler注册器
public final class FileTrackInfoHandlerRegistry {
    static var handlers: [FileTrackInfoHandler] = []

    /// 注册FileTrackInfoHandler
    /// - Parameter handler: 要注册的file track info handler
    static public func register(handler: FileTrackInfoHandler) {
        // 暂时下掉文件操作日志上报功能
//        handlers.append(handler)
    }
}
