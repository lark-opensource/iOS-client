//
//  OPBlockAPISetting.swift
//  OPBlock
//
//  Created by xiangyuanyuan on 2022/8/17.
//

import Foundation
import OPSDK
import LarkSetting
import LarkContainer
import OPBlockInterface

public final class OPBlockAPISetting {
    private let userResolver: UserResolver
    
    private var blockAPIPluginConfig: OPBlockAPIPluginConfig {
        let config: OPBlockAPIPluginConfig = userResolver.settings.staticSetting()
        return config
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private struct OPBlockAPIPluginConfig: SettingDefaultDecodable{
        static let settingKey = UserSettingKey.make(userKeyLiteral: "block_api_plugin")
        
        // 是否通过api plugin调用api
        let apiPluginEnable: Bool
        // 是否全量，即覆盖白名单
        let apiPluginOpenToAll: Bool
        // 是否禁止某个宿主通过api plugin调用api
        let apiPluginHostBlackList: [String]
        // 是否开启某个Block通过api plugin调用api
        let apiPluginBlockWhiteList: [String]
        // 是否禁止某个Block通过api plugin调用api
        let apiPluginBlockBlackList: [String]
        // 是否禁止某个API通过api plugin调用
        let apiPluginApiBlackList: [String]

        static let defaultValue = OPBlockAPIPluginConfig(
            apiPluginEnable: false,
            apiPluginOpenToAll: false,
            apiPluginHostBlackList: [],
            apiPluginBlockWhiteList: [],
            apiPluginBlockBlackList: [],
            apiPluginApiBlackList: []
        )
    }
    
    public func useAPIPlugin(host: String, blockTypeId: String, apiName: String) -> Bool {
        if !blockAPIPluginConfig.apiPluginEnable {
            return false
        }

        if blockAPIPluginConfig.apiPluginHostBlackList.contains(host) {
            return false
        }

        if !blockAPIPluginConfig.apiPluginBlockWhiteList.contains(blockTypeId) && !blockAPIPluginConfig.apiPluginOpenToAll {
            return false
        }

        if blockAPIPluginConfig.apiPluginBlockBlackList.contains(blockTypeId) {
            return false
        }

        if blockAPIPluginConfig.apiPluginApiBlackList.contains(apiName) {
            let enableTimeoutOptimize = userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableTimeoutOptimize.key)
            if !(enableTimeoutOptimize && apiName == "hideBlockLoading") {
                return false
            }
        }
        
        return true
    }
}
