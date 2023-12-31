//
//  VCRelationTagService.swift
//  
//
//  Created by ZhangJi on 2022/12/12.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon
import YYCache

final class RelationTagCache {
    static let shared = RelationTagCache()

    private let store = YYMemoryCache()
    private let lock = NSLock()

    init() {
        store.shouldRemoveAllObjectsWhenEnteringBackground = false
        store.countLimit = 50 * 5
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

public final class VCRelationTagService {
    // logger
    private static let logger = Logger.getLogger("RelationTag")

    public static func getTargetTenantInfo(httpClient: HttpClient, tenantId: Int64,
                                           completion: @escaping (TargetTenantInfo?) -> Void) -> TargetTenantInfo? {
        let request = GetTargetTenantInfoRequest(targetTenantIds: [tenantId])
        httpClient.getResponse(request) { result in
            switch result {
            case .success(let resp):
                if let info = resp.targetTenantInfos.first(where: {$0.key == tenantId}) {
                    Self.logger.info("fetch TenantInfo for tenant \(tenantId) success")
                    RelationTagCache.shared.storeTenantInfo(info.value, id: String(info.key))
                    completion(info.value)
                    return
                } else {
                    Self.logger.info("fetch TenantInfo for tenant \(tenantId) error: no info in response")
                }
            case .failure(let error):
                Self.logger.info("fetch TenantInfo for tenant \(tenantId) error: \(error)")
            }
            completion(nil)
        }

        return RelationTagCache.shared.tenantInfo(String(tenantId))
    }
}
