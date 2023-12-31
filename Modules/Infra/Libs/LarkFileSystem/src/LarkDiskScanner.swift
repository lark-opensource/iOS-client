//
//  LarkDiskScanner.swift
//  LarkFileSystem
//
//  Created by PGB on 2020/3/11.
//

import Foundation
import DateToolsSwift

public class LarkDiskScanner {
    let sandboxPath = NSHomeDirectory()

    public func scan(from baseDir: String) -> ScanResult {
        let scanResult = ScanResult()
        dfs(path: baseDir, level:baseDir.level, scanResult: scanResult)
        return scanResult
    }

    @discardableResult
    private func dfs(path: String, level: Int, scanResult: ScanResult) -> FileItem? {
        let absolutePath = sandboxPath.appendingPathComponent(path)

        let manager = FileManager.default
        var isDir = ObjCBool(false)
        guard manager.fileExists(atPath: absolutePath, isDirectory: &isDir) else { return nil }
        let fileItem = FileItem(path: path, size: fileSize(atPath: absolutePath) ?? 0, isDir: isDir.boolValue, level: level)

        if isDir.boolValue {
            for subItem in (try? FileManager.default.contentsOfDirectory(atPath: absolutePath)) ?? [] {
                let nextPath = path.appendingPathComponent(subItem)
                fileItem.size += dfs(path: nextPath, level: level + 1, scanResult: scanResult)?.size ?? 0
            }
        }

        scanResult.fileItems.append(fileItem)
        return fileItem
    }

    private func fileSize(atPath path: String) -> UInt64? {
        return (try? FileManager.default.attributesOfItem(atPath: path)[.size]) as? UInt64
    }
}

public class ScanResult {
    var fileItems: [FileItem] = []
}

public class FileItem: Hashable {
    var path: String
    var size: UInt64
    var isDir: Bool
    var level: Int
    // swiftlint:disable identifier_name
    var _trackName: String?
    // swiftlint:enable identifier_name
    var trackName: String {
        get {
            return _trackName ?? path
        }
        set {
            _trackName = newValue
        }
    }

    init(path: String, size: UInt64, isDir: Bool, level: Int) {
        self.path = path
        self.size = size
        self.isDir = isDir
        self.level = level
    }

    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        return lhs.path == rhs.path
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}
