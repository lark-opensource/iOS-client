//
//  RelationTagCache.swift
//  ByteViewCalendar
//
//  Created by lutingting on 2023/8/23.
//

import Foundation
import LarkContainer
import ByteViewCommon
import ByteViewNetwork
import ByteViewInterface
import YYCache

final class RelationTagCache {
    static let shared = RelationTagCache()

    private let store = YYMemoryCache()
    private let lock = NSLock()

    init() {
        store.shouldRemoveAllObjectsWhenEnteringBackground = false
        store.costLimit = 2 * 1024 * 1024 // 2 MB
        store.ageLimit = 2 * 60 * 60 // 2 hours

        // 切换账号后清空缓存
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeAccount),
                                               name: VCNotification.didChangeAccountNotification, object: nil)
    }

    @objc private func didChangeAccount() {
        self.clearAll()
    }

    private func tenantKey(with id: String) -> String {
        "\(id)_tag"
    }

    func storeTenantInfo(_ info: TargetTenantInfo, id: String) {
        lock.lock(); defer { lock.unlock() }
        let key = tenantKey(with: id)
        store.setObject(TenantInfoWrapper(info), forKey: key)
    }

    func tenantInfo(_ id: String) -> TargetTenantInfo? {
        lock.lock(); defer { lock.unlock() }
        let key = tenantKey(with: id)
        return (store.object(forKey: key) as? TenantInfoWrapper<TargetTenantInfo>)?.value
    }

    func removeTenantInfo(_ id: String) {
        lock.lock(); defer { lock.unlock() }
        let key = tenantKey(with: id)
        store.removeObject(forKey: key)
    }

    func clearAll() {
        lock.lock(); defer { lock.unlock() }
        store.removeAllObjects()
    }
}

private class TenantInfoWrapper<T>: NSObject {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}
