//
//  LocalStorage.swift
//  ByteViewCommon
//
//  Created by kiri on 2023/2/2.
//

import Foundation

public enum LocalStorageDirectory {
    case caches
    case document
}

public enum LocalStorageSpace {
    case global
    case user(String)
}

public enum LocalStorageDomain: Hashable {
    case root
    case child(String)
}

public protocol LocalStorageKey: Hashable {
    var rawValue: String { get }
    var domain: LocalStorageDomain { get }
}

public protocol LocalStorage {
    func value<Key: LocalStorageKey, T: Codable>(for key: Key) -> T?
    func setValue<Key: LocalStorageKey, T: Codable>(_ value: T, for key: Key)

    func bool<Key: LocalStorageKey>(for key: Key, defaultValue: Bool) -> Bool
    func set<Key: LocalStorageKey>(_ value: Bool, for key: Key)

    func int<Key: LocalStorageKey>(for key: Key, defaultValue: Int) -> Int
    func set<Key: LocalStorageKey>(_ value: Int, for key: Key)

    func double<Key: LocalStorageKey>(for key: Key, defaultValue: Double) -> Double
    func set<Key: LocalStorageKey>(_ value: Double, for key: Key)

    func string<Key: LocalStorageKey>(for key: Key) -> String?
    func set<Key: LocalStorageKey>(_ value: String, for key: Key)

    func removeValue<Key: LocalStorageKey>(for key: Key)

    func getIsoPath(root: LocalStorageDirectory, relativePath: String) -> IsoFilePath
    func getAbsPath(root: LocalStorageDirectory, relativePath: String) -> AbsFilePath
    func getAbsPath(absolutePath: String) -> AbsFilePath
}

public protocol FilePath {
    func fileExists(isDirectory: UnsafeMutablePointer<Bool>?) -> Bool

    var url: URL { get }

    var absoluteString: String { get }

    func readData(options: Data.ReadingOptions) throws -> Data
}

public protocol IsoFilePath: FilePath {
    func createFile(with data: Data?, attributes: [FileAttributeKey: Any]?) throws

    func createDirectory(withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws

    func removeItem() throws

    func writeData(_ data: Data, options: Data.WritingOptions) throws

    func appendingPath(_ relativePath: String) -> IsoFilePath
}

public protocol AbsFilePath: FilePath {
    func appendingPath(_ relativePath: String) -> AbsFilePath
}

public extension LocalStorage {
    func toStorage<Key: LocalStorageKey>(_ keyType: Key.Type) -> TypedLocalStorage<Key> {
        TypedLocalStorage(storage: self)
    }

    func toFileManager() -> LocalFileManager {
        LocalFileManager(storage: self)
    }
}

public final class LocalFileManager {
    private let storage: LocalStorage
    fileprivate init(storage: LocalStorage) {
        self.storage = storage
    }

    public func getIsoPath(root: LocalStorageDirectory, relativePath: String) -> IsoFilePath {
        storage.getIsoPath(root: root, relativePath: relativePath)
    }

    public func getAbsPath(root: LocalStorageDirectory, relativePath: String) -> AbsFilePath {
        storage.getAbsPath(root: root, relativePath: relativePath)
    }

    public func getAbsPath(absolutePath: String) -> AbsFilePath {
        storage.getAbsPath(absolutePath: absolutePath)
    }
}

public final class TypedLocalStorage<Key: LocalStorageKey> {
    private let storage: LocalStorage
    fileprivate init(storage: LocalStorage) {
        self.storage = storage
    }

    public func toFileManager() -> LocalFileManager {
        LocalFileManager(storage: self.storage)
    }
}

public extension TypedLocalStorage {
    func value<T: Codable>(forKey key: Key) -> T? { storage.value(for: key) }
    func value<T: Codable>(forKey key: Key, type: T.Type) -> T? { storage.value(for: key) }
    func setValue<T: Codable>(_ value: T?, forKey key: Key) {
        if let value {
            storage.setValue(value, for: key)
        } else {
            storage.removeValue(for: key)
        }
    }

    func bool(forKey key: Key, defaultValue: Bool = false) -> Bool { storage.bool(for: key, defaultValue: defaultValue) }
    func set(_ value: Bool, forKey key: Key) { storage.set(value, for: key) }

    func int(forKey key: Key, defaultValue: Int = 0) -> Int { storage.int(for: key, defaultValue: defaultValue) }
    func set(_ value: Int, forKey key: Key) { storage.set(value, for: key) }

    func double(forKey key: Key, defaultValue: Double = 0.0) -> Double { storage.double(for: key, defaultValue: defaultValue) }
    func set(_ value: Double, forKey key: Key) { storage.set(value, for: key) }

    func string(forKey key: Key) -> String? { storage.string(for: key) }
    func set(_ value: String?, forKey key: Key) {
        if let value {
            storage.set(value, for: key)
        } else {
            storage.removeValue(for: key)
        }
    }

    func removeValue(forKey key: Key) { storage.removeValue(for: key) }

    func getIsoPath(root: LocalStorageDirectory, relativePath: String) -> IsoFilePath {
        return storage.getIsoPath(root: root, relativePath: relativePath)
    }

    func getAbsPath(root: LocalStorageDirectory, relativePath: String) -> AbsFilePath {
        return storage.getAbsPath(root: root, relativePath: relativePath)
    }

    func getAbsPath(absolutePath: String) -> AbsFilePath {
        return storage.getAbsPath(absolutePath: absolutePath)
    }
}

public extension FilePath {
    func fileExists() -> Bool {
        var b: Bool = false
        return fileExists(isDirectory: &b) && !b
    }

    func directoryExists() -> Bool {
        var b: Bool = true
        return fileExists(isDirectory: &b) && b
    }
}
