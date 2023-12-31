//
//  KeyValue.swift
//  LarkNavigation
//
//  Created by 袁平 on 2020/12/10.
//

import UIKit
import Foundation
import LarkAccountInterface
import LarkStorage

extension KVStores {
    struct Navigation {
        static let domain = Domain.biz.core.child("Navigation")

        static func build(forUser userId: String) -> KVStore {
            return KVStores.udkv(space: .user(id: userId), domain: domain)
        }

        static func buildGlobal() -> KVStore {
            return KVStores.udkv(space: .global, domain: domain)
        }
    }
}

extension KVKeys {
    struct Navigation {
        // custom tab
        public static let navigationInfo = KVKey<String?>("navigation_info_v3")
        // 仅用来兼容4.6版本的v2数据，以后可以删除
        public static let navigationInfoV2 = KVKey<String?>("navigation_info_v2")
        public static let mainTabOrder = KVKey<String?>("main_tab_order_v2")

        public static let firstTab = KVKey<String?>("firstTab")

        public static let editGuideShowed = KVKey("edit_guide_showed", default: false)

        public static let debugLocalTabs = KVKey<[[String]]?>("debugLocalTabs")

        public static let cachedHeight = KVKey<CGFloat?>("cachedHeight")
        public static let filterCachedHeight = KVKey<CGFloat?>("filterCachedHeight")
    }
}
