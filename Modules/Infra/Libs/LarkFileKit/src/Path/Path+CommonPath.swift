//
//  Path+CommonPath.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/9.
//

import Foundation

extension Path {
    /// The path of the program's current working directory.
    internal static var current: Path {
        Path(FileManager.default.currentDirectoryPath)
    }

    /// Returns the document directory.
    public static var documentsPath: Path {
        let result = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return Path(result)
    }

    /// Returns the library/cache directory.
    public static var cachePath: Path {
        let result = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        return Path(result)
    }

    /// Returns the path to the user's temporary directory.
    public static var userTemporary: Path {
        // same as FileManager.default.temporaryDirectory
        return Path(NSTemporaryDirectory()).standardized
    }
}
