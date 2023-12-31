//
//  IsoPath+FileHandle.swift
//  LarkStorage
//
//  Created by 7Up on 2023/1/4.
//

import Foundation

extension IsoPath {
    // @available(*, deprecated, message: "Use fileHandleForReading() instead")
    public func fileReadingHandle() throws -> FileHandle {
        return try sandbox.fileHandle(atPath: base, forUsage: .reading)
    }

    // @available(*, deprecated, message: "Use fileHandleForWriting(append:) instead")
    public func fileWritingHandle() throws -> FileHandle {
        return try sandbox.fileHandle(atPath: base, forUsage: .writing(shouldAppend: false))
    }

    // @available(*, deprecated, message: "Use fileHandleForUpdating() instead")
    public func fileUpdatingHandle() throws -> FileHandle {
        return try sandbox.fileHandle(atPath: base, forUsage: .updating)
    }
}

extension IsoPath {
    public func fileHandleForReading() throws -> SBFileHandle {
        return try sandbox.fileHandle_v2(atPath: base, forUsage: .reading)
    }

    public func fileHandleForWriting(append shouldAppend: Bool) throws -> SBFileHandle {
        return try sandbox.fileHandle_v2(atPath: base, forUsage: .writing(shouldAppend: shouldAppend))
    }

    public func fileHandleForUpdating() throws -> SBFileHandle {
        return try sandbox.fileHandle_v2(atPath: base, forUsage: .updating)
    }
}
