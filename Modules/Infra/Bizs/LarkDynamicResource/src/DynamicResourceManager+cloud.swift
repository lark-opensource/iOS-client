//
//  DynamicResourceManager+cloud.swift
//  LarkDynamicResource
//
//  Created by Aslan on 2021/3/23.
//

import Foundation
import OfflineResourceManager

/// offline resource status
public enum DRStatus {
    /// unregistered
    case unRegistered
    /// registered but not ready for using
    case notReady
    /// ready for using
    case ready
}

/// offline resource status
extension OfflineResourceStatus {
    var drStatus: DRStatus {
        switch self {
        case .notReady:
            return .notReady
        case .ready:
            return .ready
        case .unRegistered:
            return .unRegistered
        }
    }
}

/// fetch result handler
public typealias OfflinePackageFetchResult = (_ isSuccess: Bool, _ status: DRStatus) -> Void

/// offline resource biz config
public struct DRBizConfig {
    /// unique id for each biz (channel name)
    public let bizID: String
    /// main key for requesting remote resource(Access Key)
    public let bizKey: String
    /// sub key for requesting remote resource
    public let subBizKey: String

    /// init biz config
    public init(bizID: String, bizKey: String, subBizKey: String) {
        self.bizID = bizID
        self.bizKey = bizKey
        self.subBizKey = subBizKey
    }

    func transformToOfflineResource() -> OfflineResourceBizConfig {
        return OfflineResourceBizConfig(bizID: self.bizID, bizKey: self.bizKey, subBizKey: self.subBizKey, bizType: .ka)
    }
}

extension DynamicResourceManager {
    func registerBiz(biz: [DRBizConfig]) {
        let bizConfigs = biz.map({ (temp) -> OfflineResourceBizConfig in
            temp.transformToOfflineResource()
        })
        OfflineResourceManager.registerBiz(configs: bizConfigs)
    }

    func fetchResource(by identifier: String, complete: OfflinePackageFetchResult?) {
        OfflineResourceManager.fetchResource(byId: identifier) { (flag, status) in
            complete?(flag, status.drStatus)
        }
    }

    func resourceRootFolderPath(identifier: String) -> String? {
        return OfflineResourceManager.rootDir(forId: identifier)
    }

    func resourceFilePath(identifier: String, path: String) -> Data? {
        return OfflineResourceManager.data(forId: identifier, path: path)
    }

    func clearCache(for identifier: String, completion: ((Bool) -> Void)?) {
        OfflineResourceManager.clear(id: identifier, completion: completion)
    }

    func resourceStatus(for identifier: String) -> DRStatus {
        return OfflineResourceManager.getResourceStatus(byId: identifier).drStatus
    }
}
