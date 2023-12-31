//
//  Path.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public final class _Path<S: SandboxType>: AnyPath, _AccessiblePath, _EnumeratablePath {

    var base: S.RawPath
    let sandbox: Sandbox<S.RawPath>
    var context: [String: Any]

    internal required init(base: S.RawPath, sandbox: Sandbox<S.RawPath>, context: [String: Any] = [:]) {
        self.base = base
        self.sandbox = sandbox
        self.context = context
    }

    // MARK: Accessible

    public var displayName: String { sandbox.displayName(atPath: base) }

    public func attributesOfItem() throws -> FileAttributes {
        return try sandbox.attributesOfItem(atPath: base)
    }

    public func attributesOfFileSystem() throws -> FileAttributes {
        return try sandbox.attributesOfFileSystem(forPath: base)
    }

    public func fileExists(isDirectory: UnsafeMutablePointer<Bool>?) -> Bool {
        return sandbox.fileExists(atPath: base, isDirectory: isDirectory)
    }

    public func contentsOfDirectory_() throws -> [String] {
        return try sandbox.contentsOfDirectory(atPath: base)
    }

    public func subpathsOfDirectory_() throws -> [String] {
        return try sandbox.subpathsOfDirectory(atPath: base)
    }

    // MARK: Move & Copy

    public func moveItem(to dstPath: _Path) throws {
        try sandbox.moveItem(atPath: base, toPath: dstPath.base)
    }

    public func forceMoveItem(to dstPath: _Path) throws {
        if dstPath.isAny {
            try dstPath.removeItem()
        }
        try moveItem(to: dstPath)
    }

    public func copyItem(to dstPath: _Path) throws {
        try dstPath.sandbox.copyItem(atPath: base, toPath: dstPath.base)
    }

    public func copyItem(from srcPath: AbsPath) throws {
        try sandbox.copyItem(atPath: srcPath, toPath: base)
    }

    // MARK: Abstract Overrides

    public override var deletingLastPathComponent: Self {
        let newBase = base.deletingLastPathComponent
        return Self(base: newBase, sandbox: sandbox, context: context)
    }

    public override var absoluteString: String { base.absoluteString }

    public override func appendingRelativePath(_ relativePath: String) -> Self {
        let newBase = base.appendingRelativePath(relativePath)
        return Self(base: newBase, sandbox: sandbox, context: context)
    }

    public override func createFile(
        with data: Data?,
        attributes: FileAttributes?
    ) throws {
        try sandbox.createFile(atPath: base, contents: data, attributes: attributes)
    }

    public override func createDirectory(
        withIntermediateDirectories createIntermediates: Bool,
        attributes: FileAttributes?
    ) throws {
        try sandbox.createDirectory(
            atPath: base,
            withIntermediateDirectories: createIntermediates,
            attributes: attributes
        )
    }

    public override func removeItem() throws {
        try sandbox.removeItem(atPath: base)
    }

    public override func setAttributes(_ attributes: FileAttributes) throws {
        try sandbox.setAttributes(attributes, atPath: base)
    }

    public override func inputStream() -> InputStream? {
        sandbox.inputStream(atPath: base)
    }

    public override func outputStream(append shouldAppend: Bool) -> OutputStream? {
        sandbox.outputStream(atPath: base, append: shouldAppend)
    }

}
