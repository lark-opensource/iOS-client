//
//  Path.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/9/20.
//

import Foundation

/// A representation of a filesystem path.
///
/// An Path instance lets you manage files in a much easier way.
///
public struct Path {
    /// The standard separator for path components.
    public static let separator = "/"

    /// The stored path string value.
    public fileprivate(set) var rawValue: String

    /// The non-empty path string value. For internal use only.
    ///
    /// Some NSAPI may throw `NSInvalidArgumentException` when path is `""`, which can't catch in swift
    /// and cause crash
    internal var safeRawValue: String {
        return rawValue.isEmpty ? "." : rawValue
    }

    internal var fmWraper = FMWrapper()

    internal final class FMWrapper {
        private lazy var _fileManager = FileManager()
        weak var delegate: FileManagerDelegate?
        /// Safe way to use fileManager
        var fileManager: FileManager {
            _fileManager.delegate = delegate
            return _fileManager
        }
    }

    /// The delegate for the file manager used by the path.
    ///
    /// **Note:** no strong reference stored in path, so make sure keep the delegate or it will be `nil`
    public var fileManagerDelegate: FileManagerDelegate? {
        get {
            return fmWraper.delegate
        }
        set {
            if !isKnownUniquelyReferenced(&fmWraper) {
                fmWraper = FMWrapper()
            }
            fmWraper.delegate = newValue
        }
    }

    // MARK: - Initialization

    /// Initializes a path to the string's value.
    public init(_ path: String) {
        self.rawValue = path
    }
}

extension Path: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}
