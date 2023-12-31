//
//  AbsPath+Readable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

extension Array {
    public static func read(from path: AbsPath) throws -> Self {
        return try path.sandbox.performReading(atPath: path, with: .empty)
    }
}

extension Data {
    public static func read(from path: AbsPath, options: ReadingOptions = []) throws -> Self {
        return try path.sandbox.performReading(atPath: path, with: .dataReadingOptions(options))
    }
}

extension NSData {
    public static func read(from path: AbsPath, options: ReadingOptions = []) throws -> Self {
        return try path.sandbox.performReading(atPath: path, with: .dataReadingOptions(options))
    }
}

extension UIImage {
    public static func read(from path: AbsPath) throws -> Self {
        return try path.sandbox.performReading(atPath: path, with: .empty)
    }
}

extension Dictionary {
    public static func read(from path: AbsPath) throws -> Self {
        return try path.sandbox.performReading(atPath: path, with: .empty)
    }
}

extension String {
    public static func read(from path: AbsPath, encoding: Encoding = .utf8) throws -> Self {
        return try path.sandbox.performReading(atPath: path, with: .stringEncoding(encoding))
    }
}

extension AbsPath {
    public func inputStream() -> InputStream? {
        return sandbox.inputStream(atPath: self)
    }
}

extension AbsPath {
    @available(*, deprecated, message: "Use fileHandleForReading() instead")
    public func fileReadingHandle() throws -> FileHandle {
        return try FileHandle(forReadingFrom: self.url)
    }
}

extension AbsPath {
    public func fileHandleForReading() throws -> SBFileHandle {
        return try sandbox.fileHandle_v2(atPath: self, forUsage: .reading)
    }
}
