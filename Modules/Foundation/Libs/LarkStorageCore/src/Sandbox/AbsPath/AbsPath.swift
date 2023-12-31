//
//  AbsPath.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

let kFileScheme = "file://"
let kSlash = "/"

/// Represents an absolute path
public final class AbsPath {
    /// 输入
    let rawValue: String
    /// 标准路径
    let stdValue: String
    var sandbox: Sandbox<AbsPath>

    private static let defaultSandbox = SandboxBase<AbsPath>()

    private init(string: String, sandbox: Sandbox<AbsPath>) {
        self.rawValue = string
        if string.hasPrefix(kSlash) {
            self.stdValue = string
        } else if string.hasPrefix(kFileScheme) {
            self.stdValue = String(string.dropFirst(kFileScheme.count))
        } else if string.hasPrefix("~") {
            SBUtils.assert(false, "unclear abs path: \(string)", event: .unclearAbsPath)
            self.stdValue = (string as NSString).expandingTildeInPath
        } else {
            #if DEBUG || ALPHA
            // FIXME: 线上上报量太大，线上不上报，后续推进存量治理后再开启
            SBUtils.assert(false, "invalid abs path: \(string)", event: .invalidAbsPath)
            #endif
            self.stdValue = kSlash + string
        }
        self.sandbox = SandboxBase<AbsPath>()
    }

    public convenience init(_ string: String) {
        self.init(string: string, sandbox: Self.defaultSandbox)
    }

    public convenience init?(url: URL) {
        guard url.isFileURL else {
            return nil
        }
        self.init(url.path)
    }

    public convenience init(stringLiteral value: String) {
        self.init(value)
    }

    public var standardized: AbsPath {
        AbsPath(string: (stdValue as NSString).standardizingPath, sandbox: sandbox)
    }

}

extension AbsPath: PathType {

    public var absoluteString: String { stdValue }

    public var deletingLastPathComponent: Self {
        let string = (absoluteString as NSString).deletingLastPathComponent
        return Self(string: string, sandbox: sandbox)
    }

    public func appendingRelativePath(_ relativePath: String) -> AbsPath {
        let string = (absoluteString as NSString).appendingPathComponent(relativePath)
        return Self(string: string, sandbox: sandbox)
    }

}

extension AbsPath: ExpressibleByStringLiteral { }

extension AbsPath: CustomStringConvertible {

    public var description: String { return stdValue }

}

// MARK: Access

extension AbsPath: _AccessiblePath {
    internal func anyPath() -> _Path<SandboxBase<AbsPath>> {
        if self.rawValue.isEmpty {
            return _Path<SandboxBase<AbsPath>>(base: .random(), sandbox: sandbox)
        }
        return _Path<SandboxBase<AbsPath>>(base: self, sandbox: sandbox)
    }

    public var displayName: String {
        anyPath().displayName
    }

    public func attributesOfItem() throws -> FileAttributes {
        try anyPath().attributesOfItem()
    }

    public func attributesOfFileSystem() throws -> FileAttributes {
        try anyPath().attributesOfFileSystem()
    }

    public func fileExists(isDirectory: UnsafeMutablePointer<Bool>?) -> Bool {
        return anyPath().fileExists(isDirectory: isDirectory)
    }

    public func contentsOfDirectory_() throws -> [String] {
        return try anyPath().contentsOfDirectory_()
    }

    public func subpathsOfDirectory_() throws -> [String] {
        return try anyPath().subpathsOfDirectory_()
    }
}

// MARK: Enumerate

extension AbsPath: _EnumeratablePath { }
