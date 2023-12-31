//
//  Path+FileAttribute.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/9.
//

import Foundation

extension Path {
    /// A new path created by making the path absolute.
    ///
    /// - Returns: If `self` begins with "/", then the standardized path is
    ///            returned. Otherwise, the path is assumed to be relative to
    ///            the current working directory and the standardized version of
    ///            the path added to the current working directory is returned.
    ///
    public var absolute: Path {
        return self.isAbsolute
            ? self.standardized
            : (Path.current + self).standardized
    }

    /// Returns `true` if the path begins with "/".
    public var isAbsolute: Bool {
        return rawValue.hasPrefix(Path.separator)
    }

    /// A new path created by removing extraneous components from the path.
    public var standardized: Path {
        return Path((self.rawValue as NSString).standardizingPath)
    }

    /// Returns the path's attributes.
    ///
    /// this method does not follow links.
    public var attributes: NSDictionary {
        FileTracker.track(self, operation: .fileAttributeRead) {
            /// 避免 NSDictionary 到 swift Dictionary 的类型隐式转化，优化性能
            (try? fmWraper.fileManager.attributesOfItem(atPath: safeRawValue) as NSDictionary) ?? NSDictionary()
        }
    }

    /// The FileType attribute for the file at the path.
    public var fileType: FileType? {
        guard let value = attributes[FileAttributeKey.type] as? String else {
            return nil
        }
        return FileType(rawValue: value)
    }

    /// Returns `true` if the path points to a directory.
    ///
    /// this method does follow links.
    public var isDirectory: Bool {
        var isDirectory: ObjCBool = false
        return fmWraper.fileManager.fileExists(atPath: safeRawValue, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }

    /// Returns `true` if the path is a directory file.
    ///
    /// this method does not follow links.
    public var isDirectoryFile: Bool {
        return fileType == .directory
    }

    /// Returns `true` if the path exists any fileType item.
    ///
    /// this method does not follow links.
    public var isAny: Bool {
        return fileType != nil
    }

    /// The creation date of the file at the path.
    public var creationDate: Date? {
        attributes[FileAttributeKey.creationDate] as? Date
    }

    /// The modification date of the file at the path.
    public var modificationDate: Date? {
        return attributes[FileAttributeKey.modificationDate] as? Date
    }

    /// - Returns: The `Path` objects url.
    public var url: URL {
        return URL(fileURLWithPath: safeRawValue, isDirectory: self.isDirectory)
    }

    /// The size of the file at the path in bytes.
    public var fileSize: UInt64? {
        if let value = attributes[FileAttributeKey.size] as? NSNumber {
            return value.uint64Value
        }
        return nil
    }

    /// 对于文件夹的路径，递归遍历所有文件，计算大小
    public var recursizeFileSize: UInt64 {
        // 可能涉及大量文件io操作，关闭上报
        FileTracker.trackerEnable = false
        defer {
            FileTracker.trackerEnable = true
        }
        let fileSize = self.fileSize ?? 0
        return isDirectory ? compactMap { $0.fileSize }.reduce(fileSize, +) : fileSize
    }
}
