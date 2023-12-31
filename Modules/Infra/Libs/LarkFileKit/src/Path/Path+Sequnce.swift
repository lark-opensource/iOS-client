//
//  Path+Sequnce.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/9.
//

import Foundation

/// An enumerator for the contents of a directory that returns the paths of all
/// files and directories contained within that directory.
public struct DirectoryEnumerator: IteratorProtocol {

    fileprivate let _path: Path
    public let enumerator: FileManager.DirectoryEnumerator?

    /// Creates a directory enumerator for the given path.
    ///
    /// - Parameter path: The path a directory enumerator to be created for.
    public init(path: Path) {
        _path = path
        enumerator = FileManager().enumerator(atPath: path.safeRawValue)
    }

    /// Returns the next path in the enumeration.
    public func next() -> Path? {
        autoreleasepool { () -> Path? in
            guard let next = enumerator?.nextObject() as? String else {
                return nil
            }
            return _path + next
        }
    }
}

// MARK: Sequence protocol comformance
extension Path: Sequence {
    /// - Returns: An *iterator* over the contents of the path.
    public func makeIterator() -> DirectoryEnumerator {
        return DirectoryEnumerator(path: self)
    }
}
