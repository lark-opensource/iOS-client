//
//  SCFileHandle.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/2/23.
//

import UIKit
import LarkSecurityComplianceInfra

// ignoring lark storage check for SBCipher implementation
// lint:disable lark_storage_check

final public class SCFileHandle {

    private let fileHandle: FileHandle

    public let path: String
    public let option: AESFileOption

    public var fd: UInt64 { UInt64(fileHandle.fileDescriptor) }

    public init(path: String, option: AESFileOption) throws {
        self.path = path
        self.option = option
        let pathURL: URL
        if #available(iOS 16.0, *) {
            pathURL = URL(filePath: path)
        } else {
            pathURL = URL(fileURLWithPath: path)
        }
        switch option {
        case .read:
            self.fileHandle = try FileHandle(forReadingFrom: pathURL)
        case .write:
            self.fileHandle = try FileHandle(forWritingTo: pathURL)
        case .append:
            self.fileHandle = try FileHandle(forUpdating: pathURL)
        }
        #if SECURITY_DEBUG
        fileHandle.isSecureAccess = true
        #endif
    }

    deinit {
        do {
            try close()
        } catch {
            SCLogger.error("AESFileHandler/close/error: \(error)")
        }
    }

    public func truncate(atOffset offset: UInt64) throws {
        if #available(iOS 13.0, *) {
            try fileHandle.truncate(atOffset: offset)
        } else {
            try objCCatch(initialValue: (), {
                self.fileHandle.truncateFile(atOffset: offset)
            })
        }
    }

    public func close() throws {
        if #available(iOS 13.0, *) {
            try fileHandle.close()
        } else {
            try objCCatch(initialValue: (), {
                self.fileHandle.closeFile()
            })
        }
    }

    public func synchronize() throws {
        if #available(iOS 13.0, *) {
            try fileHandle.synchronize()
        } else {
            try objCCatch(initialValue: (), {
                self.fileHandle.synchronizeFile()
            })
        }
    }

    public func seek(toOffset offset: UInt64) throws {
        if #available(iOS 13.0, *) {
            try fileHandle.seek(toOffset: offset)
        } else {
            try objCCatch(initialValue: (), {
                self.fileHandle.seek(toFileOffset: offset)
            })
        }
    }

    @discardableResult
    public func seekToEnd() throws -> UInt64 {
        if #available(iOS 13.4, *) {
            return try fileHandle.seekToEnd()
        } else {
            return try objCCatch(initialValue: 0, {
                self.fileHandle.seekToEndOfFile()
            })
        }
    }

    public func write(bytes: [UInt8]) throws {
        let data = Data(bytes)
        try self.write(contentsOf: data)
    }

    public func write(contentsOf data: Data) throws {
        if #available(iOS 13.4, *) {
            try fileHandle.write(contentsOf: data)
        } else {
            try objCCatch(initialValue: (), {
                self.fileHandle.write(data)
            })
        }
    }

    public func readToEnd() throws -> Data? {
        if #available(iOS 13.4, *) {
            return try fileHandle.readToEnd()
        } else {
            return try objCCatch(initialValue: nil, {
                return self.fileHandle.readDataToEndOfFile()
            })
        }
    }

    public func read(upToCount count: Int) throws -> Data? {
        if #available(iOS 13.4, *) {
            return try fileHandle.read(upToCount: count)
        } else {
            return try objCCatch(initialValue: nil, {
                return self.fileHandle.readData(ofLength: count)
            })
        }
    }

    public func offset() throws -> UInt64 {
        if #available(iOS 13.4, *) {
            return try fileHandle.offset()
        } else {
            return try objCCatch(initialValue: 0) {
                self.fileHandle.offsetInFile
            }
        }
    }
    
    private func objCCatch<R>(initialValue: R, _ block: @escaping (() -> R)) throws -> R {
        do {
            var value = initialValue
            try OCException.catch {
                value = block()
            }
            return value
        } catch {
            throw error
        }
    }
}
