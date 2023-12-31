//
//  KVStore+Lark.swift
//  LarkStorage
//
//  Created by 7Up on 2022/10/20.
//

import Foundation

public extension KVStore {
    /// 将 store 对应的文件标记为无需 iCloud 备份
    func excludeFromBackup() throws {
        guard let paths = findBase()?.filePaths else { return }
        for path in paths {
            var url = URL(fileURLWithPath: path)
            var values = try url.resourceValues(
                forKeys: [.isExcludedFromBackupKey]
            )
            if values.isExcludedFromBackup != true {
                values.isExcludedFromBackup = true
                try url.setResourceValues(values)
            }
        }
    }

    func usingCipher() -> KVStore {
        return usingCipher(suite: .aes)
    }
}

// MARK: Define

extension KVStores {

    /// 获取当前用户的 id
    public static var getCurrentUserId: (() -> String?)?

    /// 清除指定 space 的 KV 数据
    /// - Parameter space: 指定用户|全局
    /// - Parameter type: 如果为空，则清除所有 KV 数据，否则只清楚指定 type 的数据
    public static func clearAll(forSpace space: Space, type: KVStoreType? = nil) {
        // TODO: 暂只支持 KVStoreMode.normal，后续可进一步扩展
        let types: Set<KVStoreType> = type.map { [$0] } ?? [.udkv, .mmkv]
        if types.contains(.udkv) {
            let suiteName = KVStores.udSuiteName(for: space, mode: .normal)
            let store = UDKVStore(suiteName: suiteName)
            store?.clearAll()
            store?.synchronize()
        }
        if types.contains(.mmkv) {
            guard let rootPath = KVStores.mmkvRootPath(with: .normal) else { return }
            let mmkvId = KVStores.mmkvId(with: space)
            let store = MMKVStore(mmapId: mmkvId, rootPath: rootPath)
            store.clearAll()
            // store?.synchronize() mmkv 不需要调 synchronize
        }
    }

}

// TODO: 下列接口应移动到类似 KVStoreUtils 的工具类里
extension KVStores {

    static let udRegex = try? NSRegularExpression(pattern: #"^lark_storage\.(.*?)(\.Domain_(.*)\.Cipher_(.*))*\.plist$"#)
    static let mmRegex = try? NSRegularExpression(pattern: #"^lark_storage\.(.*?)(\.Domain_(.*)\.Cipher_(.*))*\.crc$"#)

    /// 遍历指定路径，根据文件名解析 space domain cipher
    private static func parseFromPath(
        _ path: AbsPath,
        regex: NSRegularExpression
    ) -> [(String, (String, String)?)] {
        guard let filenames = try? path.contentsOfDirectory_() else {
            return []
        }
        return filenames.compactMap { filename in
            let nsrange = NSRange(filename.startIndex..., in: filename)
            guard let result = regex.firstMatch(in: filename, range: nsrange),
                  result.numberOfRanges == 5,
                  let spaceRange = Range(result.range(at: 1), in: filename)
            else { return nil }

            let spacePart = String(filename[spaceRange])

            if result.range(at: 2).location == NSNotFound {
                return (spacePart, nil)
            }

            guard let domainRange = Range(result.range(at: 3), in: filename),
                  let cipherRange = Range(result.range(at: 4), in: filename)
            else { return nil }

            let domainPart = String(filename[domainRange])
            let cipherPart = String(filename[cipherRange])
            return (spacePart, (domainPart, cipherPart))
        }
    }

    /// 清除指定 domain 下所有 Space 的迁移标记
    public static func clearMigrationMarks(forDomain domain: DomainType) {
        // TODO: 考虑性能优化

        if let udRegex {
            parseFromPath(AbsPath.library + "Preferences", regex: udRegex).forEach {
                let spacePart = $0.0
                guard let space = Space.from(isolationId: spacePart) else { return }

                if let (domainPart, cipherPart) = $0.1 {
                    guard domainPart == domain.isolationChain(with: "_") else { return }
                    let suite = KVCipherSuite(name: cipherPart)
                    KVStores.udkv(space: space, domain: domain)
                        .usingCipher(suite: suite).clearMigrationMarks()
                } else {
                    KVStores.udkv(space: space, domain: domain).clearMigrationMarks()
                }
            }
        }

        if let mmRegex {
            parseFromPath(AbsPath.library + "MMKV", regex: mmRegex).forEach {
                let spacePart = $0.0
                guard let space = Space.from(isolationId: spacePart) else { return }

                if let (domainPart, cipherPart) = $0.1 {
                    guard domainPart == domain.isolationChain(with: "_") else { return }
                    let suite = KVCipherSuite(name: cipherPart)
                    KVStores.mmkv(space: space, domain: domain)
                        .usingCipher(suite: suite).clearMigrationMarks()
                } else {
                    KVStores.mmkv(space: space, domain: domain).clearMigrationMarks()
                }
            }
        }
    }

}
