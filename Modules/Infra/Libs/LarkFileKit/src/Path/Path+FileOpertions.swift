//
//  Path+FileOpertions.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/9.
//

import Foundation

// MARK: File operations
extension Path {
    /// Returns `true` if a file or directory exists at the path.
    ///
    /// this method does follow links.
    public var exists: Bool {
        guard !rawValue.isEmpty else { return false }

        return FileTracker.track(self, operation: .fileExists) {
            fmWraper.fileManager.fileExists(atPath: safeRawValue)
        }
    }

    /// Creates a file at path.
    ///
    /// Throws an error if the file cannot be created.
    ///
    /// - Throws: `FileKitError.CreateFileFail`
    ///
    /// this method does not follow links.
    ///
    /// If a file or symlink exists, this method removes the file or symlink and create regular file
    public func createFile(data: Data? = nil) throws {
        try FileTracker.track(self, operation: .createFile) {
            if !fmWraper.fileManager.createFile(atPath: safeRawValue, contents: data, attributes: nil) {
                throw FileKitError.createFileFail(path: self)
            }
        }
    }

    /// 如果文件存在，则创建文件。否则直接返回
    public func createFileIfNeeded(data: Data? = nil) throws {
        if !exists {
            try createFile(data: data)
        }
    }

    /// Creates a directory at the path.
    ///
    /// Throws an error if the directory cannot be created.
    ///
    /// - Parameter createIntermediates: If `true`, any non-existent parent
    ///                                  directories are created along with that
    ///                                  of `self`. Default value is `true`.
    ///
    /// - Throws: `FileKitError.CreateDirectoryFail`
    ///
    /// this method does not follow links.
    ///
    public func createDirectory(withIntermediateDirectories createIntermediates: Bool = true) throws {
        try FileTracker.track(self, operation: .createDirectory) {
            do {
                let manager = fmWraper.fileManager
                try manager.createDirectory(atPath: safeRawValue,
                    withIntermediateDirectories: createIntermediates,
                    attributes: nil)
            } catch {
                throw FileKitError.createDirectoryFail(path: self, error: error)
            }
        }
    }

    /// 如果目录存在，则创建，否则直接返回
    public func createDirectoryIfNeeded(withIntermediateDirectories createIntermediates: Bool = true) throws {
        if !exists {
            try createDirectory(withIntermediateDirectories: createIntermediates)
        }
    }

    // swiftlint:enable line_length

    /// Deletes the file or directory at the path.
    ///
    /// Throws an error if the file or directory cannot be deleted.
    ///
    /// - Throws: `FileKitError.DeleteFileFail`
    ///
    /// this method does not follow links.
    public func deleteFile() throws {
        try FileTracker.track(self, operation: .deleteFile) {
            do {
                try fmWraper.fileManager.removeItem(atPath: safeRawValue)
            } catch {
                throw FileKitError.deleteFileFail(path: self, error: error)
            }
        }
    }

    /// Moves the file at `self` to a path.
    ///
    /// Throws an error if the file cannot be moved.
    ///
    /// - Throws: `FileKitError.fileDoesNotExist`, `FileKitError.fileAlreadyExists`, `FileKitError.moveFileFail`
    ///
    /// this method does not follow links.
    public func moveFile(to path: Path) throws {
        try FileTracker.track(self, operation: .moveFile) {
            if self.isAny {
                if !path.isAny {
                    do {
                        try fmWraper.fileManager.moveItem(atPath: self.safeRawValue, toPath: path.safeRawValue)
                    } catch {
                        throw FileKitError.moveFileFail(from: self, to: path, error: error)
                    }
                } else {
                    throw FileKitError.fileAlreadyExists(path: path)
                }
            } else {
                throw FileKitError.fileDoesNotExist(path: self)
            }
        }
    }

    /// Copies the file at `self` to a path.
    ///
    /// Throws an error if the file at `self` could not be copied or if a file
    /// already exists at the destination path.
    ///
    /// - Throws: `FileKitError.fileDoesNotExist`, `FileKitError.fileAlreadyExists`, `FileKitError.copyFileFail`
    ///
    /// this method does not follow links.
    public func copyFile(to path: Path) throws {
        try FileTracker.track(self, operation: .copyFile) {
            if self.isAny {
                if !path.isAny {
                    do {
                        try fmWraper.fileManager.copyItem(atPath: self.safeRawValue, toPath: path.safeRawValue)
                    } catch {
                        throw FileKitError.copyFileFail(from: self, to: path, error: error)
                    }
                } else {
                    throw FileKitError.fileAlreadyExists(path: path)
                }
            } else {
                throw FileKitError.fileDoesNotExist(path: self)
            }
        }
    }

    /// Force move the file at `self` to a path.
    /// - Throws: `FileKitError.DeleteFileFail`, `FileKitError.fileDoesNotExist`,
    /// `FileKitError.fileAlreadyExists`, `FileKitError.moveFileFail`
    public func forceMoveFile(to path: Path) throws {
        if path.isAny {
            try path.deleteFile()
        }
        try moveFile(to: path)
    }
}
