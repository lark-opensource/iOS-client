//
//  String+ReadableWritable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

extension SBReadingContext {
    @inline(__always)
    static func stringEncoding(_ encoding: String.Encoding) -> Self {
        return .key(.stringEncoding, value: encoding)
    }

    var stringEncoding: String.Encoding? {
        value(forKey: .stringEncoding) as? String.Encoding
    }
}

extension SBWritingContext {
    @inline(__always)
    static func stringEncoding(_ encoding: String.Encoding) -> Self {
        return .key(.stringEncoding, value: encoding)
    }

    var stringEncoding: String.Encoding? {
        value(forKey: .stringEncoding) as? String.Encoding
    }
}

extension String: SBPathConvertible {
    static func sb_read(from path: RawPath, with context: SBReadingContext) throws -> String {
        return try String(contentsOfFile: path, encoding: context.stringEncoding ?? .utf8)
    }

    func sb_write(to path: RawPath, with context: SBWritingContext) throws {
        try self.write(toFile: path, atomically: context.atomically, encoding: context.stringEncoding ?? .utf8)
    }
}

extension String: SBDataConvertible {
    static func sb_from_data(_ data: Data, with context: SBReadingContext) throws -> String {
        guard let ret = String(data: data, encoding: .utf8) else {
            throw SandboxError.typeRead(type: "String", message: "stream mode")
        }
        return ret
    }

    func sb_to_data(with context: SBWritingContext) throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw SandboxError.typeWrite(type: "String", message: "stream mode")
        }
        return data
    }
}
