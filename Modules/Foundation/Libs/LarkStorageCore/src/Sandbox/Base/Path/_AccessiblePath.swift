//
//  _AccessiblePath.swift
//  LarkStorage
//
//  Created by 7Up on 2022/12/20.
//

import Foundation

public protocol _AccessiblePath: PathType {
    var displayName: String { get }

    /// 对应 `FileManager#attributesOfItem(atPath:)` 接口
    func attributesOfItem() throws -> FileAttributes

    /// 对应 `FileManager#attributesOfFileSystem(forPath:)` 接口
    func attributesOfFileSystem() throws -> FileAttributes

    func fileExists(isDirectory: UnsafeMutablePointer<Bool>?) -> Bool

    func contentsOfDirectory_() throws -> [String]

    func subpathsOfDirectory_() throws -> [String]
}

extension _AccessiblePath {
    private var safeAttrs: FileAttributes? { try? attributesOfItem() }

    public var attributes: FileAttributes {
        return safeAttrs ?? [:]
    }

    public var exists: Bool {
        return fileExists(isDirectory: nil)
    }

    public var isDirectory: Bool {
        var isDirectory = false
        return fileExists(isDirectory: &isDirectory) && isDirectory
    }

    /// Returns `true` if the path exists any fileType item.
    public var isAny: Bool {
        (safeAttrs?[FileAttributeKey.type] as? String) != nil
    }

    /// The size of the file at the path in bytes
    public var fileSize: UInt64? {
        guard
            let attrs = try? attributesOfItem(),
            let num = attrs[FileAttributeKey.size] as? NSNumber
        else {
            return nil
        }
        return num.uint64Value
    }

    public func childrenOfDirectory(recursive: Bool = false) throws -> [Self] {
        // 可能会有大量 IO 操作，关闭日志和 track
        SBUtils.disableLogTrack = true
        defer { SBUtils.disableLogTrack = false }

        let relativePaths: [String]
        if recursive {
            relativePaths = try subpathsOfDirectory_()
        } else {
            relativePaths = try contentsOfDirectory_()
        }
        return relativePaths.map { self + $0 }
    }

    @available(*, deprecated, message: "Please use `childrenOfDirectory(recursive: false)`")
    public func contentsOfDirectory() throws -> [Self] {
        return try childrenOfDirectory(recursive: false)
    }

    @available(*, deprecated, message: "Please use `childrenOfDirectory(recursive: true)`")
    public func subpathsOfDirectory() throws -> [Self] {
        return try childrenOfDirectory(recursive: true)
    }

    @available(*, deprecated, message: "Please use `childrenOfDirectory`")
    public func children(recursive: Bool = false) -> [Self] {
        return (try? childrenOfDirectory(recursive: recursive)) ?? []
    }

    public func eachChildren(recursive: Bool = false, _ body: (Self) throws -> Void) rethrows {
        try self.children(recursive: recursive).forEach { path in
            _ = try autoreleasepool(invoking: { try body(path) })
        }
    }
}
