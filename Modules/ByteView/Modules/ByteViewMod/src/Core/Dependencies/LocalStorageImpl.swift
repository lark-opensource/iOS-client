//
//  LocalStorageImpl.swift
//  ByteViewMod
//
//  Created by kiri on 2023/2/2.
//

import Foundation
import ByteViewCommon
import LarkStorage
import SSZipArchive

final class LocalStorageImpl: LocalStorage {
    static let logger = Logger.getLogger("LocalStorage")
    let space: LarkStorage.Space
    init(space: LarkStorage.Space) {
        self.space = space
    }

    func value<Key: LocalStorageKey, T: Codable>(for key: Key) -> T? {
        Self.logger.info("get value for key: \(key)")
        return store(key.domain).value(forKey: key.rawValue)
    }

    func setValue<Key: LocalStorageKey, T: Codable>(_ value: T, for key: Key) {
        Self.logger.info("set value for key: \(key), value: \(value)")
        store(key.domain).set(value, forKey: key.rawValue)
    }

    func bool<Key: LocalStorageKey>(for key: Key, defaultValue: Bool) -> Bool {
        let result = store(key.domain).value(forKey: KVKey(key.rawValue, default: defaultValue))
        Self.logger.info("get bool value for key: \(key), defaultValue: \(defaultValue), result: \(result)")
        return result
    }

    func set<Key: LocalStorageKey>(_ value: Bool, for key: Key) {
        Self.logger.info("set bool value for key: \(key), value: \(value)")
        store(key.domain).set(value, forKey: key.rawValue)
    }

    func int<Key: LocalStorageKey>(for key: Key, defaultValue: Int) -> Int {
        let result = store(key.domain).value(forKey: KVKey(key.rawValue, default: defaultValue))
        Self.logger.info("get int value for key: \(key), defaultValue: \(defaultValue), result: \(result)")
        return result
    }

    func set<Key: LocalStorageKey>(_ value: Int, for key: Key) {
        Self.logger.info("set Int value for key: \(key), value: \(value)")
        store(key.domain).set(value, forKey: key.rawValue)
    }

    func double<Key: LocalStorageKey>(for key: Key, defaultValue: Double) -> Double {
        let result = store(key.domain).value(forKey: KVKey(key.rawValue, default: defaultValue))
        Self.logger.info("get double value for key: \(key), defaultValue: \(defaultValue), result: \(result)")
        return result
    }

    func set<Key: LocalStorageKey>(_ value: Double, for key: Key) {
        Self.logger.info("set Double value for key: \(key), value: \(value)")
        store(key.domain).set(value, forKey: key.rawValue)
    }

    func string<Key: LocalStorageKey>(for key: Key) -> String? {
        let result: String? = store(key.domain).value(forKey: key.rawValue)
        Self.logger.info("get String value for key: \(key), result: \(result ?? "")")
        return result
    }

    func set<Key: LocalStorageKey>(_ value: String, for key: Key) {
        Self.logger.info("set String value for key: \(key), value: \(value)")
        store(key.domain).set(value, forKey: key.rawValue)
    }

    func removeValue<Key: LocalStorageKey>(for key: Key) {
        Self.logger.info("remove Value for key: \(key)")
        store(key.domain).removeValue(forKey: key.rawValue)
    }

    func getIsoPath(root: LocalStorageDirectory, relativePath: String) -> ByteViewCommon.IsoFilePath {
        let part = relativePath.isEmpty ? nil : relativePath
        return IsoPath.in(space: space, domain: Domain.biz.byteView)
            .build(forType: root.toLarkStorage(), relativePart: part).vcType
    }

    func getAbsPath(root: LocalStorageDirectory, relativePath: String) -> ByteViewCommon.AbsFilePath {
        switch root {
        case .caches:
            if relativePath.isEmpty {
                return AbsPath.cache.vcType
            } else {
                return AbsPath.cache.appendingRelativePath(relativePath).vcType
            }
        default:
            if relativePath.isEmpty {
                return AbsPath.document.vcType
            } else {
                return AbsPath.document.appendingRelativePath(relativePath).vcType
            }
        }
    }

    func getAbsPath(absolutePath: String) -> AbsFilePath {
        return AbsPath(absolutePath).vcType
    }

    private func store(_ domain: LocalStorageDomain) -> KVStore {
        KVStores.udkv(space: space, domain: domain.toLarkStorage(), mode: .normal)
    }
}

private extension LarkStorage.IsoPath {
    var vcType: IsoPathImpl {
        IsoPathImpl(self)
    }
}

private extension LarkStorage.AbsPath {
    var vcType: AbsPathImpl {
        AbsPathImpl(self)
    }
}

private struct IsoPathImpl: ByteViewCommon.IsoFilePath, CustomStringConvertible {
    let path: LarkStorage.IsoPath
    init(_ path: LarkStorage.IsoPath) {
        self.path = path
    }

    func fileExists(isDirectory: UnsafeMutablePointer<Bool>?) -> Bool {
        path.fileExists(isDirectory: isDirectory)
    }

    func createFile(with data: Data?, attributes: [FileAttributeKey: Any]?) throws {
        let dir = path.deletingLastPathComponent
        try dir.createDirectoryIfNeeded(withIntermediateDirectories: true)
        try path.createFile(with: data, attributes: attributes)
    }

    func createDirectory(withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws {
        try path.createDirectory(withIntermediateDirectories: createIntermediates, attributes: attributes)
    }

    func removeItem() throws {
        try path.removeItem()
    }

    func readData(options: Data.ReadingOptions) throws -> Data {
        try Data.read(from: path, options: options)
    }

    func writeData(_ data: Data, options: Data.WritingOptions) throws {
        let dir = path.deletingLastPathComponent
        try dir.createDirectoryIfNeeded(withIntermediateDirectories: true)
        try data.write(to: path, options: options)
    }

    var url: URL {
        path.url
    }

    var absoluteString: String {
        path.absoluteString
    }

    func appendingPath(_ relativePath: String) -> IsoFilePath {
        path.appendingRelativePath(relativePath).vcType
    }

    var description: String {
        "IsoFilePath(\(absoluteString))"
    }
}

private struct AbsPathImpl: ByteViewCommon.AbsFilePath, CustomStringConvertible {
    let path: LarkStorage.AbsPath
    init(_ path: LarkStorage.AbsPath) {
        self.path = path
    }

    func fileExists(isDirectory: UnsafeMutablePointer<Bool>?) -> Bool {
        path.fileExists(isDirectory: isDirectory)
    }

    var url: URL { path.url }

    var absoluteString: String { path.absoluteString }

    func readData(options: Data.ReadingOptions) throws -> Data {
        try Data.read(from: path, options: options)
    }

    func appendingPath(_ relativePath: String) -> AbsFilePath {
        path.appendingRelativePath(relativePath).vcType
    }

    var description: String {
        "AbsFilePath(\(absoluteString))"
    }
}

private extension LocalStorageSpace {
    func toLarkStorage() -> LarkStorage.Space {
        switch self {
        case .user(let userId):
            return .user(id: userId)
        default:
            return .global
        }
    }
}

private extension LocalStorageDomain {
    func toLarkStorage() -> LarkStorage.DomainType {
        switch self {
        case .child(let name):
            return Domain.biz.byteView.child(name)
        default:
            return Domain.biz.byteView
        }
    }
}

private extension LocalStorageDirectory {
    func toLarkStorage() -> RootPathType.Normal {
        switch self {
        case .caches:
            return .cache
        default:
            return .document
        }
    }
}
