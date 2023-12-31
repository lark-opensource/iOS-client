//
//  Path+Children.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/10.
//

import Foundation

extension Path {

    /// Returns the path's children paths.
    ///
    /// - Parameter recursive: Whether to obtain the paths recursively.
    ///                        Default value is `false`.
    ///
    /// this method follow links if recursive is `false`, otherwise not follow links
    public func children(recursive: Bool = false) -> [Path] {
        FileTracker.track(self, operation: .fileChildren) {
            let obtainFunc = recursive
                ? fmWraper.fileManager.subpathsOfDirectory(atPath:)
                : fmWraper.fileManager.contentsOfDirectory(atPath:)
            return (try? obtainFunc(safeRawValue))?.map { self + Path($0) } ?? []
        }
    }


    public func eachChildren(recursive: Bool = false, _ body: (Path) throws -> Void) rethrows {
        // 可能涉及大量文件io操作，关闭上报
        FileTracker.trackerEnable = false
        defer {
            FileTracker.trackerEnable = true
        }
        let allChildren = children(recursive: recursive)
        try allChildren.forEach { (path) in
            _ = try autoreleasepool(invoking: {
                try body(path)
            })
        }
    }
}
