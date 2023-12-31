//
//  FileType.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/9/21.
//

import Foundation

/// The type attribute for a file at a path.
public enum FileType: String {

    /// The file is a directory.
    case directory

    /// The file is a regular file.
    case regular

    /// The file is a symbolic link.
    case symbolicLink

    /// The file is a socket.
    case socket

    /// The file is a characer special file.
    case characterSpecial

    /// The file is a block special file.
    case blockSpecial

    /// The type of the file is unknown.
    case unknown

    /// Creates a FileType from an `FileAttributeType` attribute.
    ///
    /// - Parameter rawValue: The raw value to create from.
    public init?(rawValue: String) {
        switch rawValue {
        case FileAttributeType.typeDirectory.rawValue:
            self = .directory
        case FileAttributeType.typeRegular.rawValue:
            self = .regular
        case FileAttributeType.typeSymbolicLink.rawValue:
            self = .symbolicLink
        case FileAttributeType.typeSocket.rawValue:
            self = .socket
        case FileAttributeType.typeCharacterSpecial.rawValue:
            self = .characterSpecial
        case FileAttributeType.typeBlockSpecial.rawValue:
            self = .blockSpecial
        case FileAttributeType.typeUnknown.rawValue:
            self = .unknown
        default:
            return nil
        }
    }

    /// The `FileAttributeType` attribute for `self`.
    public var rawValue: String {
        switch self {
        case .directory:
            return FileAttributeType.typeDirectory.rawValue
        case .regular:
            return FileAttributeType.typeRegular.rawValue
        case .symbolicLink:
            return FileAttributeType.typeSymbolicLink.rawValue
        case .socket:
            return FileAttributeType.typeSocket.rawValue
        case .characterSpecial:
            return FileAttributeType.typeCharacterSpecial.rawValue
        case .blockSpecial:
            return FileAttributeType.typeBlockSpecial.rawValue
        case .unknown:
            return FileAttributeType.typeUnknown.rawValue
        }
    }
}
