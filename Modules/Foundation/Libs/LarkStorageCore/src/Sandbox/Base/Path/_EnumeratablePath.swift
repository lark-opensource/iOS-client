//
//  _EnumeratablePath.swift
//  LarkStorage
//
//  Created by 7Up on 2022/12/20.
//

import Foundation

/// An enumerator for the contents of a directory that returns the paths of all
/// files and directories contained within that directory.
public struct DirectoryEnumerator<Path: PathType>: IteratorProtocol, Sequence {

    fileprivate let root: Path
    public let base: FileManager.DirectoryEnumerator?

    /// Creates a directory enumerator for the given path.
    ///
    /// - Parameter path: The path a directory enumerator to be created for.
    init(root: Path) {
        self.root = root
        self.base = FileManager().enumerator(atPath: root.absoluteString)
    }

    /// Returns the next path in the enumeration.
    public func next() -> Path? {
        autoreleasepool { () -> Path? in
            guard let next = base?.nextObject() as? String else {
                return nil
            }
            return root + next
        }
    }

}

public protocol _EnumeratablePath: PathType {
    func enumerator() -> DirectoryEnumerator<Self>?
}

extension _EnumeratablePath {
    public func enumerator() -> DirectoryEnumerator<Self>? {
        return DirectoryEnumerator(root: self)
    }
}

extension _EnumeratablePath where Self: _AccessiblePath {
    /// 深度遍历统计目录里的文件大小
    /// - Parameter ignoreDirectorySize: 是否忽略目录的大小
    public func recursiveFileSize(ignoreDirectorySize: Bool = false) -> UInt64 {
        // 批量计算，关闭 log 和 track
        SBUtils.disableLogTrack = true
        defer { SBUtils.disableLogTrack = false }

        let fileSize = self.fileSize ?? 0
        guard isDirectory else { return fileSize }

        let enumerator = DirectoryEnumerator(root: self)
        if ignoreDirectorySize {
            return enumerator.compactMap { item in
                return item.isDirectory ? nil : item.fileSize
            }.reduce(0, +)
        } else {
            return enumerator.compactMap(\.fileSize).reduce(fileSize, +)
        }
    }
}
