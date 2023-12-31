//
//  VkeyExecutor.swift
//  LarkClean
//
//  Created by 7Up on 2023/7/13.
//

import Foundation
import LarkStorage
import EEAtomic

final class CleanVkeyItem {
    let vkey: CleanIndex.Vkey.Unified

    @SafeLazy var store: KVStore

    init(vkey: CleanIndex.Vkey.Unified) {
        self.vkey = vkey
        self._store = SafeLazy {
            let store: KVStore
            switch vkey.type {
            case .udkv:
                store = KVStores.udkv(space: vkey.space, domain: vkey.domain)
            case .mmkv:
                store = KVStores.mmkv(space: vkey.space, domain: vkey.domain)
            @unknown default:
                fatalError("unknown type")
            }
            return store
        }
    }

    func cleanAll() {
        store.clearAll()
        store.synchronize()
    }
}

class CleanVkeyExecutor: Executor {
    let params: ExecutorParams

    private var items = [CleanVkeyItem]()
    private var runningFlag = false

    init(params: ExecutorParams) {
        self.params = params
    }

    func setup() {
        items = []
        guard case .create = params.scene else { return }

        let indexes = CleanRegistry.allIndexes(with: params.context, cachedKey: params.identifier)
        items = indexes.values.flatMap { indexes in
            return indexes.compactMap { index -> CleanVkeyItem? in
                guard
                    case .vkey(let vk) = index,
                    case .unified(let uni) = vk
                else {
                    return nil
                }
                return CleanVkeyItem(vkey: uni)
            }
        }
    }

    /// 计算需要 clean 的 task count
    func uncompletedCount() -> Int {
        return 1
    }

    func runOnce(with handler: @escaping ExecutorEventHandler) {
        assert(!runningFlag)
        runningFlag = true
        let queue = DispatchQueue.global()
        guard !items.isEmpty else {
            queue.async { handler(.endSucceed) }
            return
        }

        let totalCount = items.count
        var finishCount = 0
        for item in items {
            item.cleanAll()
            finishCount += 1
            queue.async {
                handler(.progress(finished: finishCount, total: totalCount))
                if finishCount == totalCount {
                    handler(.endSucceed)
                }
            }
        }
    }

    func dropAll() {
        // do nothing
    }
}
