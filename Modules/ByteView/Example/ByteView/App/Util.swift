//
//  Util.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/10.
//

import Foundation
import ByteViewCommon

@inline(never)
@usableFromInline
func methodNotImplemented(file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("Method must be overridden", file: file, line: line)
}

struct Util {
    /// URL to bundle .DocumentDirectory
    static var documentsDirectoryURL: URL {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return dir
        } else {
            return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        }
    }
}

extension Logger {
    static let demo = Logger.getLogger("Demo")
}
