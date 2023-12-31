//
//  AnyPath.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

enum PathOperationError: Swift.Error {
    case createFileFail(path: String)
}

let abstractMethodMessage = "Abstract method"

public class AnyPath: PathType {

    // MARK: `PathType` Impl

    open var deletingLastPathComponent: Self {
        fatalError(abstractMethodMessage, file: #fileID, line: #line)
    }

    public var absoluteString: String {
        fatalError(abstractMethodMessage, file: #fileID, line: #line)
    }

    public func appendingRelativePath(_ relativePath: String) -> Self {
        fatalError(abstractMethodMessage, file: #fileID, line: #line)
    }

    // MARK: Create/Remove

    public func createFile(
        with data: Data?,
        attributes: FileAttributes?
    ) throws {
        fatalError(abstractMethodMessage, file: #fileID, line: #line)
    }

    public func createDirectory(
        withIntermediateDirectories createIntermediates: Bool,
        attributes: FileAttributes?
    ) throws {
        fatalError(abstractMethodMessage, file: #fileID, line: #line)
    }

    public func removeItem() throws {
        fatalError(abstractMethodMessage, file: #fileID, line: #line)
    }

    // MARK: InputStream/OutputStream

    public func inputStream() -> InputStream? {
        fatalError(abstractMethodMessage, file: #fileID, line: #line)
    }

    public func outputStream(append shouldAppend: Bool) -> OutputStream? {
        fatalError(abstractMethodMessage, file: #fileID, line: #line)
    }

    public func setAttributes(_ attributes: FileAttributes) throws {
        fatalError(abstractMethodMessage, file: #fileID, line: #line)
    }

}

// MARK: - Extensions

public extension AnyPath {
    func createFile(with data: Data? = nil) throws {
        try createFile(with: data, attributes: nil)
    }

    func createDirectory(withIntermediateDirectories createIntermediates: Bool = true) throws {
        try createDirectory(withIntermediateDirectories: createIntermediates, attributes: nil)
    }
}

public extension _AccessiblePath where Self: AnyPath {
    func createFileIfNeeded(with data: Data? = nil) throws {
        guard !exists else { return }
        try createFile(with: data, attributes: nil)
    }

    func createDirectoryIfNeeded(withIntermediateDirectories createIntermediates: Bool = true) throws {
        guard !exists else { return }
        try createDirectory(withIntermediateDirectories: createIntermediates, attributes: nil)
    }
}

// MARK: Archive/Unarchive

public extension AnyPath {
    func archive(rootObject: Any) -> Bool {
        return SandboxTracker.track(.archive, path: self) {
            return NSKeyedArchiver.archiveRootObject(rootObject, toFile: absoluteString)
        }
    }

    func unarchive() -> Any? {
        return SandboxTracker.track(.unarchive, path: self) {
            return NSKeyedUnarchiver.unarchiveObject(withFile: absoluteString)
        }
    }
}
