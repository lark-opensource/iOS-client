//
//  SandboxTracker.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public final class SandboxTracker {

    public enum Operation: String {
        case fileExists
        case createFile
        case createDirectory
        case removeItem
        case moveItem
        case copyItem
        case attributes
        case systemAttributes
        case displayName
        case directoryContents
        case directorySubpaths
        case performReading
        case performWriting
        case inputStream
        case outputStream
        case fileHandle
        case archive
        case unarchive
        case setAttributes
    }

    static func track<T>(
        _ operation: Operation,
        path: PathType,
        block: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let succeed: Bool
        defer {
            track(operation: operation, path: path, startTime: startTime, succeed: succeed)
        }
        let result: T
        do {
            result = try block()
            succeed = true
        } catch {
            succeed = false
            throw error
        }
        return result
    }

    static func track(
        operation: Operation,
        path: PathType,
        startTime: CFAbsoluteTime,
        succeed: Bool
    ) {
        guard LarkStorageFG.trackEvent else {
            return
        }
        let endTime = CFAbsoluteTimeGetCurrent()
        let event = TrackerEvent(
            name: "lark_storage_sandbox_operation",
            metric: [
                "latency": (endTime - startTime) * Double(Const.thousand),
                "succeed": succeed ? 1.0 : 0.0
            ],
            category: [
                "is_main_thread": Thread.isMainThread,
                "operation": operation.rawValue
            ],
            extra: [:]
        )
        DispatchQueue.global(qos: .utility).async { Dependencies.post(event) }
    }

}

public typealias SandboxAction = SandboxTracker.Operation
