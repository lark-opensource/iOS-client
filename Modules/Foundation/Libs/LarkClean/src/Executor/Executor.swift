//
//  Executor..swift
//  LarkClean
//
//  Created by 7Up on 2023/7/9.
//

import Foundation
import LKCommonsLogging
import LarkStorage
import EEAtomic
import MMKV

enum ExecutorEvent {
    case progress(finished: Int, total: Int)
    case end(failCodes: [Int])

    static let endSucceed: Self = .end(failCodes: [])
}

typealias ExecutorEventHandler = (ExecutorEvent) -> Void

protocol Executor: AnyObject {
    func setup()

    /// 未完成的数量
    func uncompletedCount() -> Int

    func runOnce(with handler: @escaping ExecutorEventHandler)

    func dropAll()
}

extension Executor {
    var log: Log { cleanLogger }
}

func makeIdentifier() -> String {
    return String(Int((Date().timeIntervalSince1970 * 1_000).rounded()))
}

private var initialInt32: Int32 = 0
@inline(__always)
func uuint() -> Int32 {
    return OSAtomicIncrement32(&initialInt32) & Int32.max
}

final class ExecutorParams {
    enum Scene {
        case create, resume
    }

    enum StoreKeys: String {
        case context = "lark_clean_context_v1"
        case retryCount = "lark_clean_retry_count"
    }

    let identifier: String
    private(set) var context: CleanContext
    private(set) var scene: Scene
    private(set)var retryCount: Int = 3
    @SafeLazy var store: KVStore

    private init(identifier: String, context: CleanContext, scene: Scene, store: @escaping () -> KVStore) {
        self.identifier = identifier
        self.context = context
        self._store = SafeLazy { store() }
        self.scene = scene
    }

    static func allLocalIdentifiers() -> [String] {
        let basePath: IsoPath =
            .in(space: .global, domain: Domain.biz.infra.child("LarkClean"))
            .build(forType: .document)
        guard let contents = try? basePath.contentsOfDirectory_() else {
            return []
        }
        return contents.filter { !$0.isEmpty }
    }

    static func rootPath(forIdentifier identifier: String ) -> IsoPath {
        return IsoPath.in(
            space: .global,
            domain: Domain.biz.infra.child("LarkClean")
        ).build(forType: .document, relativePart: identifier)
    }

    private static func makeStore(for identifier: String) -> KVStore {
        let storeDir = rootPath(forIdentifier: identifier)
        try? storeDir.createDirectoryIfNeeded()
        return KVStores.mmkv(
            mmapID: "CleanPath",
            rootPath: storeDir.absoluteString,
            space: .global,
            domain: Domain.biz.infra.child("LarkClean")
        )
    }

    static func create(identifier: String, context: CleanContext, retryCount: Int) -> Self {
        let params = Self(identifier: identifier, context: context, scene: .create, store: { makeStore(for: identifier) })
        params.retryCount = retryCount
        // cache context, retryCount
        params.store.set(context, forKey: StoreKeys.context.rawValue)
        params.store.set(retryCount, forKey: StoreKeys.retryCount.rawValue)
        return params
    }

    static func resume(with identifier: String) -> Self? {
        let store = makeStore(for: identifier)
        guard let context: CleanContext = store.value(forKey: StoreKeys.context.rawValue) else {
            return nil
        }

        let ret = Self(identifier: identifier, context: context, scene: .resume, store: { store })
        if let count: Int = store.value(forKey: StoreKeys.retryCount.rawValue) {
            ret.retryCount = count
        }
        return ret
    }
}
