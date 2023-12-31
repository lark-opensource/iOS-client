//
//  TTGeckoAbility.swift
//  SpaceKit
//
//  Created by Webster on 2019/12/5.
//

import Foundation
import IESGeckoKit
import OfflineResourceManager


public protocol TTGeckoAbility: AnyObject {
    func setup(by appId: String)
    func setDeviceID(_ deviceId: String)
    func setDomain(_ domain: String)
    func registerBiz(_ biz: GeckoBizConfig)
    func fetchResource(by identifier: String, resourceVersion: String, customParams: [String: Any]?, completed: @escaping GeckoFetchSingleFinishBlock)
    func resourceRootFolderPath(identifier: String) -> String?
    func clearCache(for identifier: String)
    func resourceStatus(for identifier: String) -> OfflineResourceStatus
}

//直接调用gecko的原生接口实现热更
public class TTGeckoRawImpl: TTGeckoAbility {

    private var configs: [GeckoBizConfig] = []
    
    public init() {}

    public func setup(by appId: String) {
        IESGurdKit.setup(withAppId: appId, appVersion: "99.0.0", cacheRootDirectory: nil)
    }

    public func setDeviceID(_ deviceId: String) {
        IESGurdKit.deviceID = deviceId
    }

    public func setDomain(_ domain: String) {
        IESGurdKit.platformDomain = domain
    }

    public func registerBiz(_ biz: GeckoBizConfig) {
        configs.append(biz)
        IESGurdKit.registerAccessKey(biz.accessKey, channels: [biz.channel])
    }

    public func fetchResource(by identifier: String, resourceVersion: String, customParams: [String: Any]?, completed: @escaping GeckoFetchSingleFinishBlock) {
        let failConfig = GeckoBizConfig(identifier: identifier, key: "", channel: "")
        let failResult = GeckoFetchResult(config: failConfig, status: .unRegistered)
        guard let config = configs.first(where: { $0.identifier == identifier }) else {
            completed(false, failResult)
            return
        }
        IESGurdKit.syncResources { params in
            params.accessKey = config.accessKey
            params.channels = [config.channel]
            params.resourceVersion = resourceVersion
            if let customParams = customParams {
                params.customParams = customParams
            }
        } completion: { finish, result in
            let status = result.first { return $0.key == config.channel }?.value ?? 0
            let syncStatus = IESGurdSyncStatus(rawValue: Int(truncating: status)) ?? .syncStatusUnknown
            var reportStatus = OfflineResourceStatus.notReady
            if syncStatus == .syncStatusSuccess {
                reportStatus = .ready
            }
            let result = GeckoFetchResult(config: config, status: reportStatus)
            completed(finish, result)
        }
    }

    public func resourceRootFolderPath(identifier: String) -> String? {
        guard let config = configs.first(where: { $0.identifier == identifier }) else {
            return nil
        }
        return IESGurdKit.rootDir(forAccessKey: config.accessKey, channel: config.channel)
    }

    public func clearCache(for identifier: String) {
        guard let config = configs.first(where: { $0.identifier == identifier }) else {
            return
        }
        IESGurdKit.clearCache(forAccessKey: config.accessKey, channel: config.channel)
    }

    public func resourceStatus(for identifier: String) -> OfflineResourceStatus {
        return .ready
    }
}
