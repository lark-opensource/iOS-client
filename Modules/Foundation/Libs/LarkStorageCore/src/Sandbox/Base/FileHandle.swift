//
//  FileHandle.swift
//  LarkStorage
//
//  Created by zhangwei on 2023/9/5.
//

import Foundation

public protocol SBFileHandle: AnyObject {
    func write(contentsOf data: Data) throws

    func offset() throws -> UInt64

    func seek(toOffset offset: UInt64) throws
    func seekToEnd() throws -> UInt64

    func readToEnd() throws -> Data?
    func read(upToCount count: Int) throws -> Data?

    func close() throws
    func synchronize() throws
}

@available(iOS 13.4, *)
@nonobjc extension FileHandle: SBFileHandle { }

final class OldFileHandle: SBFileHandle {
    let inner: FileHandle
    init(inner: FileHandle) {
        self.inner = inner
    }

    func write(contentsOf data: Data) throws {
        try LarkStorageObjcExceptionHandler.catchException {
            self.inner.write(data)
        }
    }

    func offset() throws -> UInt64 {
        var out: UInt64 = 0
        try LarkStorageObjcExceptionHandler.catchException {
            out = self.inner.offsetInFile
        }
        return out
    }

    func seek(toOffset offset: UInt64) throws {
        try LarkStorageObjcExceptionHandler.catchException {
            self.inner.seek(toFileOffset: offset)
        }
    }

    func seekToEnd() throws -> UInt64 {
        var ret: UInt64 = 0
        try LarkStorageObjcExceptionHandler.catchException {
            ret = self.inner.seekToEndOfFile()
        }
        return ret
    }

    func synchronize() throws {
        try LarkStorageObjcExceptionHandler.catchException {
            self.inner.synchronizeFile()
        }
    }

    func close() throws {
        try LarkStorageObjcExceptionHandler.catchException {
            self.inner.closeFile()
        }
    }

    func readToEnd() throws -> Data? {
        var ret: Data?
        try LarkStorageObjcExceptionHandler.catchException {
            ret = self.inner.readDataToEndOfFile()
        }
        return ret
    }

    func read(upToCount count: Int) throws -> Data? {
        var ret: Data?
        try LarkStorageObjcExceptionHandler.catchException {
            ret = self.inner.readData(ofLength: count)
        }
        return ret
    }
}

extension FileHandle {
    // FIXME: 临时 public，供外部灰度使用，后续需要改为 internal
    public var sb: SBFileHandle {
        if #available(iOS 13.4, *) {
            return self
        } else {
            return OldFileHandle(inner: self)
        }
    }
}
