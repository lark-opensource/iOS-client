//
//  KeyValue.swift
//  LarkGuide
//
//  Created by 李昊哲 on 2023/6/13.
//  

import Foundation
import LarkStorage

extension KVStores {
    struct Guide {
        static let domain = Domain.biz.core.child("Guide")

        /// 构建全局维度的 `KVStore`
        static func global() -> KVStore {
            return KVStores.udkv(space: .global, domain: domain)
        }

        /// 构建用户维度的 `KVStore`
        static func user(id: String) -> KVStore {
            return KVStores.udkv(space: .user(id: id), domain: domain)
        }
    }
}

extension KVKeys {
    struct Guide {
        /// 用户维度
        static let guideData = KVKey<Data?>("GUIDE_DATA_KEY")

        /// 全局维度
        static let GuideList = KVKey<[String: Bool]?>("GUIDELIST")
#if DEBUG
        static let DisablePopup = KVKey("DISABLE_POPUP", default: false)
#endif

        static func guideKey(_ key: String) -> KVKey<Data?> {
            return .init("lark_guide_\(key)")
        }

        // 添加标记guide key
        static func mapGuideKey(_ key: String) -> KVKey<Data?> {
            return .init("lk_guide_\(key)")
        }
    }
}
