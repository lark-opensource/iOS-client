//
//  IsoPath+TypeReadWrite.swift
//  LarkStorage
//
//  Created by 7Up on 2023/7/28.
//

import Foundation

// MARK: String

public extension String {
    static func read(from path: IsoPath, encoding: Encoding = .utf8) throws -> Self {
        return try path.sandbox.performReading(atPath: path.base, with: .stringEncoding(encoding))
    }

    func write(to path: IsoPath, atomically: Bool = true, encoding: Encoding = .utf8) throws {
        var context: SBWritingContext = .atomically(atomically)
        context.set(encoding, forKey: .stringEncoding)
        try path.sandbox.performWriting(self, atPath: path.base, with: context)
    }
}

// MARK: Data & NSData

public extension Data {
    static func read(from path: IsoPath, options: ReadingOptions = []) throws -> Self {
        return try path.sandbox.performReading(atPath: path.base, with: .dataReadingOptions(options))
    }

    func write(to path: IsoPath, options: WritingOptions) throws {
        try path.sandbox.performWriting(self, atPath: path.base, with: .dataWritingOptions(options))
    }

    func write(to path: IsoPath, atomically: Bool = true) throws {
        try write(to: path, options: atomically ? [.atomic] : [])
    }
}

public extension NSData {
    static func read(from path: IsoPath, options: ReadingOptions = []) throws -> Self {
        return try path.sandbox.performReading(atPath: path.base, with: .dataReadingOptions(options))
    }

    func write(to path: IsoPath, options: WritingOptions) throws {
        try path.sandbox.performWriting(self, atPath: path.base, with: .dataWritingOptions(options))
    }

    func write(to path: IsoPath, atomically: Bool = true) throws {
        try write(to: path, options: atomically ? [.atomic] : [])
    }
}

// MARK: Image

public extension UIImage {
    static func read(from path: IsoPath) throws -> Self {
        return try path.sandbox.performReading(atPath: path.base, with: .empty)
    }

    func write(to path: IsoPath, atomically: Bool = true) throws {
        try path.sandbox.performWriting(self, atPath: path.base, with: .atomically(atomically))
    }
}

// MARK: Dictionary

public extension Dictionary {
    static func read(from path: IsoPath) throws -> Self {
        return try path.sandbox.performReading(atPath: path.base, with: .empty)
    }

    func write(to path: IsoPath, atomically: Bool = true) throws {
        try path.sandbox.performWriting(self, atPath: path.base, with: .atomically(atomically))
    }
}

public extension NSDictionary {
    static func read(from path: IsoPath) throws -> NSDictionary {
        let wrapper: NSDictionaryWrapper = try path.sandbox.performReading(atPath: path.base, with: .empty)
        return wrapper.inner
    }

    func write(to path: IsoPath, atomically: Bool) throws {
        let wrapper = NSDictionaryWrapper(inner: self)
        try path.sandbox.performWriting(wrapper, atPath: path.base, with: .atomically(atomically))
    }
}

// MARK: Array

public extension Array {
    static func read(from path: IsoPath) throws -> Self {
        try path.sandbox.performReading(atPath: path.base, with: .empty)
    }

    func write(to path: IsoPath, atomically: Bool = true) throws {
        try path.sandbox.performWriting(self, atPath: path.base, with: .atomically(atomically))
    }
}
