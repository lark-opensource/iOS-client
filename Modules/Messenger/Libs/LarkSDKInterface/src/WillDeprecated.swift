//
//  WillDeprecated.swift
//  LarkSDKInterface
//
//  Created by zhangwei on 2023/8/15.
//

import LarkSetting
import LarkFileKit

// lint:disable lark_storage_migrate_check

/// NOTE: 本文件的逻辑用于 Messenger 业务的沙盒操作从 LarkFileKit/系统原生 向 LarkStorage 过渡；
/// 预期 2023.Q3 完成全量并下线。
/// By @zhangwei.wy

public struct PathWrapper {
    public typealias Old = LarkFileKit.Path

    public static var useLarkStorage: Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: "ios.lark_storage.sandbox.messenger.p2") // Global
    }()

    var wrapped: String
    public init(_ wrapped: String) {
        self.wrapped = wrapped
    }

    public var exists: Bool {
        if Self.useLarkStorage {
            return wrapped.asAbsPath().exists
        } else {
            return Old(wrapped).exists
        }
    }

    public var isDirectory: Bool {
        if Self.useLarkStorage {
            return wrapped.asAbsPath().isDirectory
        } else {
            return Old(wrapped).isDirectory
        }
    }

    public var fileSize: UInt64? {
        if Self.useLarkStorage {
            return wrapped.asAbsPath().fileSize
        } else {
            return Old(wrapped).fileSize
        }
    }

    public var url: URL {
        if Self.useLarkStorage {
            return wrapped.asAbsPath().url
        } else {
            return Old(wrapped).url
        }
    }

    public func inputStream() -> InputStream? {
        if Self.useLarkStorage {
            return wrapped.asAbsPath().inputStream()
        } else {
            return Old(wrapped).inputStream()
        }
    }

    public func copyFile(to toPath: PathWrapper) throws {
        if Self.useLarkStorage {
            try wrapped.asAbsPath().notStrictly.copyItem(to: toPath.wrapped.asAbsPath())
        } else {
            try Old(wrapped).copyFile(to: Old(toPath.wrapped))
        }
    }

    public func moveFile(to toPath: PathWrapper) throws {
        if Self.useLarkStorage {
            try wrapped.asAbsPath().notStrictly.moveItem(to: toPath.wrapped.asAbsPath())
        } else {
            try Old(wrapped).moveFile(to: Old(toPath.wrapped))
        }
    }

    public func forceMoveFile(to toPath: PathWrapper) throws {
        if Self.useLarkStorage {
            try wrapped.asAbsPath().notStrictly.forceMoveItem(to: toPath.wrapped.asAbsPath())
        } else {
            try Old(wrapped).forceMoveFile(to: Old(toPath.wrapped))
        }
    }

    public func deleteFile() throws {
        if Self.useLarkStorage {
            try wrapped.asAbsPath().notStrictly.removeItem()
        } else {
            try Old(wrapped).deleteFile()
        }
    }
}

extension Data {
    public static func read_(from url: URL) throws -> Data {
        if PathWrapper.useLarkStorage {
            return try Data.read(from: url.asAbsPath())
        } else {
            return try Data(contentsOf: url)
        }
    }

    public static func read_(from path: String) throws -> Data {
        if PathWrapper.useLarkStorage {
            return try Data.read(from: path.asAbsPath())
        } else {
            return try Data(contentsOf: URL(fileURLWithPath: path))
        }
    }
}

extension UIImage {
    public static func read_(from path: String) -> UIImage? {
        if PathWrapper.useLarkStorage {
            return try? UIImage.read(from: path.asAbsPath())
        } else {
            return UIImage(contentsOfFile: path)
        }
    }
}

public struct VideoCacheConfig {
    static let relativePath = "/Library/Caches"

    public static func replaceHomeDirectory(forPath path: String) -> String? {
        if PathWrapper.useLarkStorage {
            return path.fixingHomeDirectory(withRootType: .cache)?.absoluteString
        } else {
            let key = relativePath
            if let range = path.range(of: key) {
                return path.replacingOccurrences(of: path[..<range.lowerBound], with: NSHomeDirectory())
            }
            return nil
        }
    }
}
