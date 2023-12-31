//
//  ReadableWritable.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/9/20.
//

import Foundation

/// A type that can be used to read from and write to File instances.
public typealias ReadableWritable = Readable & Writable

/// A type that can be used to read from File instances.
public protocol Readable {

    /// Creates `Self` from the contents of a Path.
    ///
    /// - Parameter path: The path being read from.
    ///
    static func read(from path: Path) throws -> Self

}

/// A type that can be used to write to File instances.
public protocol Writable {

    /// Writes `self` to a Path.
    func write(to path: Path) throws

    /// Writes `self` to a Path.
    ///
    /// - Parameter path: The path being written to.
    /// - Parameter useAuxiliaryFile: If `true`, the data is written to an
    ///                               auxiliary file that is then renamed to the
    ///                               file. If `false`, the data is written to
    ///                               the file directly.
    ///
    func write(to path: Path, atomically useAuxiliaryFile: Bool) throws

}

extension Writable {

    /// Writes `self` to a Path atomically.
    ///
    /// - Parameter path: The path being written to.
    ///
    public func write(to path: Path) throws {
        try write(to: path, atomically: true)
    }

}
