//
//  Array+ReadableWritable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

extension Array: SBPathConvertible {
    static func sb_read(from path: RawPath, with context: SBReadingContext) throws -> Self {
        guard
            let contents = NSArray(contentsOfFile: path),
            let array = contents as? Array
        else {
            throw SandboxError.typeRead(type: "Array", message: "path: \(path)")
        }
        return array
    }

    func sb_write(to path: RawPath, with context: SBWritingContext) throws {
        let nsArray = self as NSArray
        guard nsArray.write(toFile: path, atomically: context.atomically) else {
            throw SandboxError.typeWrite(type: "Array", message: "path: \(path)")
        }
    }
}

extension Array: SBDataConvertible {
    static func sb_from_data(_ data: Data, with context: SBReadingContext) throws -> Self {
        let contents = try PropertyListSerialization.propertyList(from: data, format: nil)
        guard let array = contents as? Array else {
            throw SandboxError.typeRead(type: "Array", message: "stream mode")
        }
        return array
    }

    func sb_to_data(with context: SBWritingContext) throws -> Data {
        return try PropertyListSerialization.data(fromPropertyList: self, format: .xml, options: .zero)
    }
}
