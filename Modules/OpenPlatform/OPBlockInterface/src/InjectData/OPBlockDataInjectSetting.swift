//
//  OPBlockDataInjectSetting.swift
//  OPBlockInterface
//
//  Created by xiangyuanyuan on 2022/7/17.
//

import Foundation
import OPSDK
import LarkSetting

public final class OPBlockDataInjectSetting {
    
    private static let blockDataInjectConfig: OPBlockDataInjectConfig = {
        @Setting(key: .make(userKeyLiteral: "block_data_inject"))
        var config: OPBlockDataInjectConfig?
        return config ?? .default
    }()
    
    private struct OPBlockDataInjectConfig: Codable {
        
        // 是否开启数据注入功能
        let dataInjectEnable: Bool
        // 是否全量，即覆盖白名单
        let dataInjectOpenToAll: Bool
        // 是否禁用某个宿主的数据注入
        let dataInjectHostBlackList: [String]
        // 是否开启某个Block的数据注入功能
        let dataInjectBlockWhiteList: [String]
        // 是否禁用某个Block的数据注入
        let dataInjectBlockBlackList: [String]
        // 支持哪些类型数据的注入
        let dataInjectBlockDataTypeList: [String]
        
        static var `default`: OPBlockDataInjectConfig {
            return OPBlockDataInjectConfig(dataInjectEnable: false,
                                           dataInjectOpenToAll: false,
                                           dataInjectHostBlackList: [],
                                           dataInjectBlockWhiteList: [],
                                           dataInjectBlockBlackList: [],
                                           dataInjectBlockDataTypeList: [])
        }
    }
    
    public static func isEnableInjectData(host: String,
                                          blockTypeId: String,
                                          dataType: BlockDataSourceType) -> Bool {
        
        if !blockDataInjectConfig.dataInjectEnable {
            return false
        }

        if blockDataInjectConfig.dataInjectHostBlackList.contains(host) {
            return false
        }

        if !blockDataInjectConfig.dataInjectBlockWhiteList.contains(blockTypeId) && !blockDataInjectConfig.dataInjectOpenToAll {
            return false
        }

        if blockDataInjectConfig.dataInjectBlockBlackList.contains(blockTypeId) {
            return false
        }
        
        // 只有guideInfo配置需要判断，entity数据注入不判断
        if dataType == .guideInfo && !blockDataInjectConfig.dataInjectBlockDataTypeList.contains(dataType.rawValue) {
            return false
        }
        
        return true
    }
}
