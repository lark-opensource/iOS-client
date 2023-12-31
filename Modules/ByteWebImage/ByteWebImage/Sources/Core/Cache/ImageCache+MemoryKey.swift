//
//  ImageCache+MemoryKey.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/8/29.
//

import Foundation
import ThreadSafeDataStructure

extension ImageCache {

    enum ProcessKey {

        case origin(_ origin: Key)

        case process(_ origin: Key, _ base: Key, _ config: ImageProcessConfig)

        var config: ImageProcessConfig {
            switch self {
            case .origin:
                return .default
            case .process(_, _, let config):
                return config
            }
        }
    }

    /// 内存键
    final class MemoryKey {

        private var map: SafeDictionary<String, Set<ImageProcessConfig>> = [:] + .readWriteLock

        func setObject(forKey key: ProcessKey) {
            guard case let .process(_, base, config) = key else {
                return
            }
            var set = map[base] ?? []
            set.insert(config)
            map[base] = set

            Log.trace("Set memory cache, remind map: \(map)")
        }

        private func qualityKeys(_ base: String, _ config: ImageProcessConfig) -> [String] {
            guard let list = map[base] else {
                return []
            }
            let result = list.filter { obj in
                // 1. 没有转换器 / 转换器相同
                if obj.transformID != config.transformID, !obj.transformID.isEmpty {
                    return false
                }
                // 2. 没有裁剪 / 裁剪相同
                if obj.needCrop != config.needCrop {
                    return false
                }
                if obj.crop != config.crop, obj.crop != .zero {
                    return false
                }
                // 3. 都无降采样 / 降采样程度较低
                if obj.downsample == .zero {
                    return true
                } else if config.downsample == .zero {
                    return false
                } else {
                    return (obj.downsample.width >= config.downsample.width)
                    && (obj.downsample.height >= config.downsample.height)
                }
            }.map { base.bt.processKey(config: $0) }
            return result
        }

        func objects(forKey key: ProcessKey, fuzzy: Bool) -> [String] {
            switch key {
            case .origin(let origin):
                return [origin]
            case let .process(origin, base, config):
                if fuzzy {
                    return [origin] + qualityKeys(base, config) + [base]
                } else {
                    return [origin, base]
                }
            }
        }

        func removeObject(forKey key: ProcessKey, fuzzy: Bool) {
            switch key {
            case .origin(let origin):
                if fuzzy {
                    map[origin] = nil
                }
            case let .process(_, base, config):
                map[base]?.remove(config)
            }

            Log.trace("Remove memory cache, remind map: \(map)")
        }

        func removeAllObjects() {
            map.removeAll()

            Log.trace("Clean memory cache, remind map: \(map)")
        }
    }
}
