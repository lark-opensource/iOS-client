//
//  KeyValue.swift
//  LarkVersion
//
//  Created by zhangwei on 2022/11/17.
//

import Foundation
import LarkStorage

extension KVStores {
    struct Version {
        static var glboal: KVStore {
            KVStores.udkv(space: .global, domain: Domain.biz.core.child("Version"))
        }
    }
}

extension KVKeys {
    struct Version {
        /// 用户无关
        static let lastUpgradeTapLaterTime = KVKey("last_update_urgent_tap_later_time", default: 0.0)
        static let lastRemoveUpdateNoticeVersion = KVKey("last_remove_update_notice_version", default: "")
        static let lastUpdateShowAlertVersion = KVKey("last_remove_update_notice_version", default: "")
        static let lastInhouseUpdateAlertTime = KVKey("last_inhouse_update_alert_time", default: 0.0)
        /// 用来保存KA发布策略ID
        static let kaDeployStrategyIdKey = KVKey("KAUpgrade.kaDeployStrategyId", default: "")
        /// 用来保存KA发布单ID
        static let kaDeployTicketIdKey = KVKey("KAUpgrade.kaDeployTicketId", default: "")
        /// 用来保存LarkVersion发布单ID
        static let planIdKey = KVKey("KAUpgrade.planId", default: "")
        /// 用来保存KA升级前的version
        static let KAOldVerisonKey = KVKey("KAUpgrade.KAOldVerison", default: "")
    }
}
