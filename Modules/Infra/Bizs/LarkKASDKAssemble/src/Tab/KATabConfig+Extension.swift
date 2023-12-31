//
//  KATabConfig+Extension.swift
//  KATabRegistry
//
//  Created by Supeng on 2021/11/5.
//

import Foundation
import LarkTab
import LarkNavigation
#if canImport(LKTabExternal)
import LKTabExternal
#endif

#if canImport(LKTabExternal)
extension KATabConfig {
    var tabURL: String { "//client/customNative/home?key=\(appId)" }
    var larkTabConfig: TabConfig { TabConfig(key: appId) }
    var larkTab: Tab { Tab(url: tabURL, appType: .appTypeCustomNative, key: appId) }
}

let allConfigs: [KATabConfig] = {
    KATabExternal.getTabs()
}()
#endif
