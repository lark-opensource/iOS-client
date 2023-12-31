//
//  AbsPathConvertiable.swift
//  LarkStorage
//
//  Created by 7Up on 2023/4/3.
//

import Foundation

public protocol AbsPathConvertiable {
    func asAbsPath() -> AbsPath
}

extension AbsPath: AbsPathConvertiable {
    public func asAbsPath() -> AbsPath {
        return self
    }
}

extension String: AbsPathConvertiable {
    public func asAbsPath() -> AbsPath {
        return AbsPath(self)
    }
}

extension URL: AbsPathConvertiable {
    public func asAbsPath() -> AbsPath {
        return AbsPath(self.path)
    }
}

extension IsoPath: AbsPathConvertiable {
    public func asAbsPath() -> AbsPath {
        return AbsPath(absoluteString)
    }
}

extension Bundle {
    public var bundleAbsPath: AbsPath {
        bundleURL.asAbsPath()
    }

    public func absPath(forResource name: String?, ofType ext: String?) -> AbsPath? {
        return path(forResource: name, ofType: ext).map { $0.asAbsPath() }
    }

    public func absPath(forResource name: String?, ofType ext: String?, inDirectory subpath: String?) -> AbsPath? {
        return path(forResource: name, ofType: ext, inDirectory: subpath).map { $0.asAbsPath() }
    }
}

extension AbsPathConvertiable {
    /// 将 HomeDirectory 替换为当前 `NSHomeDirectory`
    public func fixingHomeDirectory(withRootType rootType: RootPathType.Normal) -> AbsPath? {
        let pathStr = asAbsPath().stdValue
        guard let range = pathStr.range(of: rootType.relativePath) else {
            return nil
        }
        return "\(NSHomeDirectory())/\(pathStr[range.lowerBound...])".asAbsPath()
    }
}
