//
//  String+ReadableWritable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

extension UIImage: SBPathConvertible {
    static func sb_read(from path: RawPath, with context: SBReadingContext) throws -> Self {
        guard let contents = Self(contentsOfFile: path) else {
            throw SandboxError.typeRead(type: "UIImage", message: "path: \(path)")
        }
        return contents
    }

    func sb_write(to path: RawPath, with context: SBWritingContext) throws {
        let data: Data = pngData() ?? Data()
        try data.sb_write(to: path, with: context)
    }
}

extension UIImage: SBDataConvertible {
    static func sb_from_data(_ data: Data, with context: SBReadingContext) throws -> Self {
        guard let ret = Self(data: data) else {
            throw SandboxError.typeRead(type: "UIImage", message: "stream mode")
        }
        return ret
    }

    func sb_to_data(with context: SBWritingContext) throws -> Data {
        guard let data = pngData() else {
            throw SandboxError.typeWrite(type: "UIImage", message: "fail to trans to pngData")
        }
        return data
    }
}
