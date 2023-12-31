//
//  AbsPath+Common.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public extension AbsPath {
    /// path/to/sandbox
    static let home = AbsPath((NSHomeDirectory() as NSString).standardizingPath)

    /// path/to/sandbox/Documents
    static let document = builtInPath(for: .document)

    /// path/to/sandbox/Library
    static let library = builtInPath(for: .library)

    /// path/to/sandbox/Library/Caches
    static let cache = builtInPath(for: .cache)

    /// path/to/sandbox/tmp
    static let temporary = builtInPath(for: .temporary)

    /// path/to/sharedContainer
    static var sharedRoot: AbsPath? {
        builtInPath(for: .root, appGroupId: Dependencies.appGroupId)
    }
}

extension AbsPath {

    public static func builtInPath(for type: RootPathType.Normal) -> AbsPath {

        let dir: FileManager.SearchPathDirectory
        switch type {
        case .temporary:
            return AbsPath((NSTemporaryDirectory() as NSString).standardizingPath)
        case .document:
            dir = .documentDirectory
        case .library:
            dir = .libraryDirectory
        case .cache:
            dir = .cachesDirectory
        }
        guard let str = NSSearchPathForDirectoriesInDomains(dir, .userDomainMask, true).first else {
            return AbsPath.home + type.relativePath
        }
        return AbsPath(str)
    }

    static func builtInPath(for type: RootPathType.Shared, appGroupId: String?) -> AbsPath? {
        guard
            let appGroupId,
            let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        else {
            return nil
        }
        let rootPath = url.asAbsPath()
        switch type {
        case .root:
            return rootPath
        case .library:
            return rootPath + "Library"
        case .cache:
            return rootPath + "Library/Caches"
        }
    }

}

extension AbsPath {
    /// random temporary path
    internal static func random() -> AbsPath {
        AbsPath.temporary + UUID().uuidString
    }
}
