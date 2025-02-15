//
//  FileKitError.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/9/21.
//

import Foundation

// MARK: FileKitError

/// An error that can be thrown by FileKit.
public enum FileKitError: Error {

    /// A file does not exist.
    case fileDoesNotExist(path: Path)

    /// A file already exists at operation destination.
    case fileAlreadyExists(path: Path)

    /// Could not change the current directory.
    case changeDirectoryFail(from: Path, to: Path, error: Error)

    /// A file could not be created.
    case createFileFail(path: Path)

    /// A directory could not be created.
    case createDirectoryFail(path: Path, error: Error)

    /// A file could not be deleted.
    case deleteFileFail(path: Path, error: Error)

    /// A file could not be read from.
    case readFromFileFail(path: Path, error: Error)

    /// A file could not be written to.
    case writeToFileFail(path: Path, error: Error)

    /// A file could not be moved.
    case moveFileFail(from: Path, to: Path, error: Error)

    /// A file could not be copied.
    case copyFileFail(from: Path, to: Path, error: Error)

    /// One or many attributes could not be changed.
    case attributesChangeFail(path: Path, error: Error)

    // MARK: - Reason

    /// An error that could be cause of `FileKitError`
    enum ReasonError: Error {
        /// Failed to read or convert to specific type.
        case conversion(Any)
        /// A file stream/handle is alread closed.
        case closed
        /// Failed to encode string using specific encoding.
        case encoding(String.Encoding, data: String)
    }
}

// MARK: - Message
extension FileKitError {

    /// The reason for why the error occured.
    public var message: String {
        switch self {
        case let .fileDoesNotExist(path):
            return "File does not exist at \"\(path)\""
        case let .fileAlreadyExists(path):
            return "File already exists at \"\(path)\""
        case let .changeDirectoryFail(fromPath, toPath, _):
            return "Could not change the directory from \"\(fromPath)\" to \"\(toPath)\""
        case let .createFileFail(path):
            return "Could not create file at \"\(path)\""
        case let .createDirectoryFail(path, _):
            return "Could not create a directory at \"\(path)\""
        case let .deleteFileFail(path, _):
            return "Could not delete file at \"\(path)\""
        case let .readFromFileFail(path, _):
            return "Could not read from file at \"\(path)\""
        case let .writeToFileFail(path, _):
            return "Could not write to file at \"\(path)\""
        case let .moveFileFail(fromPath, toPath, _):
            return "Could not move file at \"\(fromPath)\" to \"\(toPath)\""
        case let .copyFileFail(fromPath, toPath, _):
            return "Could not copy file from \"\(fromPath)\" to \"\(toPath)\""
        case let .attributesChangeFail(path, _):
            return "Could not change file attrubutes at \"\(path)\""
        }
    }
}

// MARK: - CustomStringConvertible
extension FileKitError: CustomStringConvertible {

    /// A textual representation of `self`.
    public var description: String {
        return String(describing: type(of: self)) + "(" + message + ")"
    }

}

// MARK: - CustomDebugStringConvertible
extension FileKitError: CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        if let error = error {
            return "\(self.description) \(error)"
        }
        return self.description
    }

}

// MARK: - underlying error
extension FileKitError {

    /// Return the underlying error if any
    public var error: Error? {
        switch self {
        case .changeDirectoryFail(_, _, let error),
             .createDirectoryFail(_, let error),
             .deleteFileFail(_, let error),
             .readFromFileFail(_, let error),
             .writeToFileFail(_, let error),
             .moveFileFail(_, _, let error),
             .copyFileFail(_, _, let error):
            return error
        case .fileDoesNotExist,
             .fileAlreadyExists,
             .createFileFail,
             .attributesChangeFail:
            return nil
        }
    }
}
