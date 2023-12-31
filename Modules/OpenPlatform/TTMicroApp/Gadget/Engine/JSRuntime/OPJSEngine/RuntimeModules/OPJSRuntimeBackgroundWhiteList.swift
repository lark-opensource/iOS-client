//
//  OPJSRuntimeBackgroundWhiteList.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/8/9.
//

import Foundation
import LarkSetting
import LKCommonsLogging

extension OPJSRuntimeAPIDispatchModule {
    
    struct WhiteListSetting {
        static let logger = Logger.log(WhiteListSetting.self, category: "")
        static let key = "op_api_gadget_background_white_list"
        static let globalEnable = "global_enable"
        static let appIDs = "app_ids"
        static let apiWhiteList = "api_white_list"
        static let from = "from"
    }
    
    static func apiBackgroundWhiteList(appID: String) -> [String]? {
        guard let settings = try? SettingManager.shared.setting(with: WhiteListSetting.key) else {
            WhiteListSetting.logger.info("cannot find setting")
            return nil
        }
        let from = settings[WhiteListSetting.from] as? String ?? "local"
        guard let globalEnable = settings[WhiteListSetting.globalEnable] as? Bool,
              let appIDs = settings[WhiteListSetting.appIDs] as? [String] else {
            WhiteListSetting.logger.info("cannot find globalEnable or appIDs, from: \(from)")
            return nil
        }
        guard globalEnable || appIDs.contains(appID) else {
            WhiteListSetting.logger.info("globalEnable: \(globalEnable), appID: \(appID) is not include in: \(appIDs), from: \(from)")
            return nil
        }
        let apiWhiteList = settings[WhiteListSetting.apiWhiteList] as? [String]
        WhiteListSetting.logger.info("apiWhiteList: \(apiWhiteList ?? []), from: \(from)")
        return apiWhiteList
    }
}
