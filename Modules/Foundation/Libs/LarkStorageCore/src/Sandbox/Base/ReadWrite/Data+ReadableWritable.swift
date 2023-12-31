//
//  Data+ReadableWritable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

extension SBReadingContext {
    @inline(__always)
    static func dataReadingOptions(_ options: Data.ReadingOptions) -> Self {
        .key(.dataReadingOptions, value: options)
    }

    var dataReadingOptions: Data.ReadingOptions {
        (value(forKey: .dataReadingOptions) as? Data.ReadingOptions) ?? []
    }
}

extension SBWritingContext {
    @inline(__always)
    static func dataWritingOptions(_ options: Data.WritingOptions) -> Self {
        .key(.dataWritingOptions, value: options)
    }

    var dataWritingOptions: Data.WritingOptions {
        (value(forKey: .dataWritingOptions) as? Data.WritingOptions) ?? []
    }
}

extension Data: SBPathConvertible {
    static func sb_read(from path: RawPath, with context: SBReadingContext) throws -> Self {
        return try Self(contentsOf: path.asAbsPath().url, options: context.dataReadingOptions)
    }

    func sb_write(to path: RawPath, with context: SBWritingContext) throws {
        try self.write(to: path.asAbsPath().url, options: context.dataWritingOptions)
    }
}

extension Data: SBDataConvertible {
    static func sb_from_data(_ data: Data, with context: SBReadingContext) throws -> Self {
        return data
    }

    func sb_to_data(with context: SBWritingContext) throws -> Data {
        return self
    }
}

extension NSData: SBPathConvertible {
    static func sb_read(from path: RawPath, with context: SBReadingContext) throws -> Self {
        return try Self(contentsOf: path.asAbsPath().url, options: context.dataReadingOptions)
    }

    func sb_write(to path: RawPath, with context: SBWritingContext) throws {
        try self.write(to: path.asAbsPath().url, options: context.dataWritingOptions)
    }
}

extension NSData: SBDataConvertible {
    static func sb_from_data(_ data: Data, with context: SBReadingContext) throws -> Self {
        return Self(data: data)
    }

    func sb_to_data(with context: SBWritingContext) throws -> Data {
        return self as Data
    }
}
