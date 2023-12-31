//
//  TTGeckoLarkImpl.swift
//  SpaceKit
//
//  Created by Webster on 2019/12/9.
//

import Foundation
import OfflineResourceManager

public class TTGeckoLarkImpl: TTGeckoAbility {

    private var configs: [GeckoBizConfig] = []
    
    public init() {}

    //在lark工程由lark保证，所以是空方法
    public func setup(by appId: String) { }
    //在lark工程由lark保证，所以是空方法
    public func setDeviceID(_ deviceId: String) { }
    //在lark工程由lark保证，所以是空方法
    public func setDomain(_ domain: String) { }

    public func registerBiz(_ biz: GeckoBizConfig) {
        configs.append(biz)
        let resourceBizConfig = OfflineResourceBizConfig(bizID: biz.identifier, bizKey: biz.accessKey, subBizKey: biz.channel)
        OfflineResourceManager.registerBiz(configs: [resourceBizConfig])
    }

    public func fetchResource(by identifier: String, resourceVersion: String, customParams: [String: Any]?, completed: @escaping GeckoFetchSingleFinishBlock) {
        let failConfig = GeckoBizConfig(identifier: identifier, key: "", channel: "")
        let failResult = GeckoFetchResult(config: failConfig, status: .notReady)
        guard let config = configs.first(where: { $0.identifier == identifier }) else {
            completed(false, failResult)
            return
        }
        OfflineResourceManager.fetchResource(byId: identifier, resourceVersion: resourceVersion, customParams: customParams) { (finish, status) in
            let result = GeckoFetchResult(config: config, status: status)
            completed(finish, result)
        }
        
    }
    
    public func resourceRootFolderPath(identifier: String) -> String? {
        guard let config = configs.first(where: { $0.identifier == identifier }) else {
            return nil
        }
        return OfflineResourceManager.rootDir(forId: config.identifier)
    }

    public func clearCache(for identifier: String) {
        guard let config = configs.first(where: { $0.identifier == identifier }) else {
            return
        }
        _ = OfflineResourceManager.clear(id: config.identifier)
    }

    public func resourceStatus(for identifier: String) -> OfflineResourceStatus {
        guard let config = configs.first(where: { $0.identifier == identifier }) else {
            return .notReady
        }
        return OfflineResourceManager.getResourceStatus(byId: config.identifier)
    }

}
