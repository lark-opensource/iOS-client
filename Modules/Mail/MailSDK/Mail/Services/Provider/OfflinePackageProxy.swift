//
//  OfflinePackageProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/12/12.
//

import Foundation

/// fetch result handler
public typealias OfflinePackageFetchResult = (_ isSuccess: Bool, _ status: ResourceStatus) -> Void

/// offline resource status
public enum ResourceStatus {
    /// unregistered
    case unRegistered
    /// registered but not ready for using
    case notReady
    /// ready for using
    case ready
}

/// offline resource biz config
public struct ResourceBizConfig {
    /// unique id for each biz
    public let bizID: String
    /// main key for requesting remote resource
    public let bizKey: String
    /// sub key for requesting remote resource
    public let subBizKey: String

    /// init biz config
    public init(bizID: String, bizKey: String, subBizKey: String) {
        self.bizID = bizID
        self.bizKey = bizKey
        self.subBizKey = subBizKey
    }
}

public protocol OfflinePackageProxy {
    func userIsOversea() -> Bool

    func registerBiz(_ biz: [ResourceBizConfig])

    func fetchResource(by identifier: String, resourceVersion: String, complete: OfflinePackageFetchResult?)

    func resourceRootFolderPath(identifier: String) -> String?

    func clearCache(for identifier: String)

    func resourceStatus(for identifier: String) -> ResourceStatus
}
