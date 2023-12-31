//
//  MeetTabRelationTagService.swift
//  ByteViewTab
//
//  Created by ZhangJi on 2022/12/2.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon

final class MeetTabRelationTagCache {
    static let shared = MeetTabRelationTagCache()
    // nolint-next-line: magic number
    private let store = MemoryCache(countLimit: 50 * 5, ageLimit: 2 * 60 * 60)

    init() {
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
        store.setValue(info, forKey: tenantKey(with: id))
    }

    func tenantInfo(_ id: String) -> TargetTenantInfo? {
        store.value(forKey: tenantKey(with: id))
    }

    func removeTenantInfo(_ id: String) {
        store.removeValue(forKey: tenantKey(with: id))
    }

    func clearAll() {
        store.removeAll()
    }
}

final class MeetTabRelationTagService {
    // logger
    private static let logger = Logger.getLogger("RelationTag")
    private let httpClient: HttpClient
    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    public func getTargetTenantInfo(tenantId: Int64, completion: @escaping (TargetTenantInfo?) -> Void) -> TargetTenantInfo? {
        let request = GetTargetTenantInfoRequest(targetTenantIds: [tenantId])
        httpClient.getResponse(request) { result in
            switch result {
            case .success(let resp):
                if let info = resp.targetTenantInfos.first(where: {$0.key == tenantId}) {
                    Self.logger.info("fetch TenantInfo for tenant \(tenantId) success")
                    MeetTabRelationTagCache.shared.storeTenantInfo(info.value, id: String(info.key))
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

        return MeetTabRelationTagCache.shared.tenantInfo(String(tenantId))
    }
}
