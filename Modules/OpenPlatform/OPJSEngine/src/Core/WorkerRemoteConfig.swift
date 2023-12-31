//
//  OPWorkerRemoteConfig.swift
//  OPJSEngine
//
//  Created by qsc on 2022/12/22.
//

import Foundation
import LarkSetting

struct WorkerTypeConfig: Decodable {
    let oldJscoreWhitelist: [String]
    let jscoreWhitelist: [String]
}

struct VmsdkConfig: Decodable {
    let openToAll: Bool
    let blackList: [String]
    let whiteList: [String]
}

struct WorkerRemoteConfig: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "op_js_worker_config")
    let workerType: WorkerTypeConfig
    let vmsdk: VmsdkConfig?
}

extension WorkerRemoteConfig {
    /**
     是否启动 vmsdk worker
    - openToAll ,且命中黑名单 -> false
    - 未 openToAll, 命中白名单 -> true
     */
    func shouldUseVmsdkWorker(for appID: String) -> Bool {
        guard let vmsdkConfig = vmsdk else {
            return false
        }
        if vmsdkConfig.openToAll {
            if vmsdkConfig.blackList.contains(appID) {
                return false
            } else {
                return true
            }
        } else {
            if vmsdkConfig.blackList.contains(appID) {
                return false
            }
            
            if vmsdkConfig.whiteList.contains(appID) {
                return true
            }
            
            return false
        }
    }
    
}
