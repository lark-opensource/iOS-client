//
//  PathType.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

/// Represents a path
public protocol PathType {
    /// Returns the absolute string for the Path
    var absoluteString: String { get }

    /// Returns a Path by appending the given relativePath to self.
    func appendingRelativePath(_ relativePath: String) -> Self

    /// A new path made by deleting the last path component from self.
    var deletingLastPathComponent: Self { get }
}

extension PathType {
    /// A file URL referencing the local file at path.
    public var url: URL {
        URL(fileURLWithPath: absoluteString)
    }

    /// The last path component.
    public var lastPathComponent: String {
        return (absoluteString as NSString).lastPathComponent
    }
}

extension PathType {
    public func parent() -> Self {
        return self.deletingLastPathComponent
    }
}

extension PathType {
    /// Converts a `String` to a `Path` and returns the concatenated result.
    static public func + (lhs: Self, rhs: String) -> Self {
        return lhs.appendingRelativePath(rhs)
    }

    /// Appends the right relativePath to the left path.
    static public func += (lhs: inout Self, rhs: String) {
        lhs = lhs.appendingRelativePath(rhs)
    }
}

extension PathType {
    /// 对 absoluteString 进行标准化处理，然后拆分为 Components
    /// 第一个元素是 "/"
    func rawComponents() -> [String] {
        let standardized = (absoluteString as NSString).standardizingPath
        return (standardized as NSString).pathComponents
    }

    /// 计算 `self` 相对于 `base` 的 components
    func relativeComponents(to base: PathType) -> [String]? {
        let testComps = self.rawComponents()
        let baseComps = base.rawComponents()
        guard testComps.count >= baseComps.count else { return nil }
        for index in 0..<baseComps.count {
            // test match
            if testComps[index] != baseComps[index] {
                return nil
            }
        }
        return testComps.suffix(testComps.count - baseComps.count)
    }

    /// 判断 self 和 other 是否是相同路径（标准化后）
    public func isSame(as other: any PathType, caseSensitive: Bool = true) -> Bool {
        var slf = self.rawComponents()
        var oth = other.rawComponents()
        if !caseSensitive {
            slf = slf.map { $0.lowercased() }
            oth = oth.map { $0.lowercased() }
        }
        return slf == oth
    }

    /// 判断 `self` 是否是 `base` 的子路径
    public func starts(with base: PathType) -> Bool {
        return relativeComponents(to: base) != nil
    }

    /// 计算相对路径
    /// - Returns: 如果返回 nil，表示 `self` 不是 `base` 的子路径；否则返回 `self` 相对于 `base` 的相对路径
    public func relativePath(to base: PathType) -> String? {
        guard let comps = relativeComponents(to: base) else {
            return nil
        }
        return comps.joined(separator: "/")
    }
}
