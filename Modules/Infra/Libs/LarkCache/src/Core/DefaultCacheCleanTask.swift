//
//  DefaultCache.swift
//  LarkCache
//
//  Created by Supeng on 2020/8/11.
//

import Foundation
import LarkFoundation
import LKCommonsLogging
import EEAtomic
import LarkStorage

public struct DefaultCacheCleanTask: CleanTask {
    static let logger = Logger.log(DefaultCacheCleanTask.self, category: "LarkCache")

    public var name: String { "DefaultCacheCleanTask" }

    public init() {}

    public func clean(config: CleanConfig, completion: @escaping Completion) {
        Self.logger.info("handle clean with config: \(config)")
        let currentTime = CFAbsoluteTimeGetCurrent()
        var result = TaskResult()
        defer {
            result.costTime = Int((CFAbsoluteTimeGetCurrent() - currentTime) * 1_000)
            result.completed = true
            completion(result)
            Self.logger.info("finish cleanning. config: \(config), result: \(result)")
        }
        if config.isUserTriggered {
            let size = self.size(config: config)
            CacheManager.shared.cleanAll()

            // 直接清理 Library/Caches, tmp 目录
            cleanCachesDirectory()
            cleanTemporaryDirectory()

            CacheManager.shared.reinitAll()

            result.sizes = [.bytes(size)]
        } else {
            let allCaches = Self.allCaches()
            let toalSizeCleaned = AtomicInt64(0)
            let tracker = CacheCleanTracker()

            DispatchQueue.concurrentPerform(iterations: allCaches.count) { index in
                let cache = allCaches[index]
                let cleanConfig = config.cacheConfig[cache.cleanIdentifier] ?? {
                    return .init(timeLimit: 0, sizeLimit: 0)
                }()

                let before = (size: cache.totalDiskSize, time: CFAbsoluteTimeGetCurrent())
                cache.cleanDiskCache(cleanConfig: cleanConfig)
                let after = (size: cache.totalDiskSize, time: CFAbsoluteTimeGetCurrent())

                _ = toalSizeCleaned.add(Int64(before.size - after.size))
                tracker.addItem(
                    bytes: before.size - after.size,
                    costTime: Int((after.time - before.time) * 1_000),
                    forIdentifier: cache.cleanIdentifier
                )
            }

            result.sizes = [.bytes(Int(toalSizeCleaned.value))]

            DispatchQueue.global(qos: .utility).async { tracker.flush() }
        }
    }

    public static func allCaches() -> [Cache] {
        KVStates.cachePathToCleanIdentifierMap.compactMap { (relativePath, cleanIdentifier) -> Cache? in
            let subStringFromDir: (CacheDirectory) -> (CacheDirectory, String)? = { cacheDir in
                guard relativePath.hasPrefix(cacheDir.dirName + "/") else {
                    return nil
                }
                let index = relativePath.index(relativePath.startIndex, offsetBy: cacheDir.dirName.count + 1)
                return (cacheDir, String(relativePath[index...]))
            }

            let dirAndRelativeToDirPath = subStringFromDir(CacheDirectory.cache)

            return dirAndRelativeToDirPath.flatMap {
                CacheManager.shared.cache(relativePath: $0.1,
                                          directory: $0.0,
                                          cleanIdentifier: cleanIdentifier)
            }
        }
    }

    public func size(config: CleanConfig, completion: @escaping Completion) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileSize = size(config: config)
        let endTime = CFAbsoluteTimeGetCurrent()
        completion(TaskResult(completed: true, costTime: Int((endTime - startTime) * 1_000), size: .bytes(fileSize)))
    }

    private func size(config: CleanConfig) -> Int {
        if config.isUserTriggered {
            let fileSize = AbsPath.cache.recursiveFileSize()
            return Int(truncatingIfNeeded: fileSize)
        } else {
            return Self.allCaches().map(\.totalDiskSize).reduce(0, +)
        }
    }

    func cleanCachesDirectory() {
        let cachePath = IsoPath.notStrictly.cache()
        try? cachePath.removeItem()
        try? cachePath.createDirectoryIfNeeded()
    }

    func cleanTemporaryDirectory() {
        let appleDyld = "com.apple.dyld"
        let tmpDyldPath = IsoPath.notStrictly.temporary() + appleDyld
        let documentDyldPath = IsoPath.global.in(domain: Domain.biz.core.child("Dyld")).build(.document) + appleDyld

        try? documentDyldPath.removeItem()
        try? tmpDyldPath.moveItem(to: documentDyldPath)
        try? tmpDyldPath.removeItem()
        try? documentDyldPath.moveItem(to: tmpDyldPath)
    }
}
