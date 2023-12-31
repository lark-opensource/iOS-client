//
//  KeyValue.swift
//  LarkAI
//
//  Created by zhangwei on 2022/12/26.
//

import Foundation
import LarkStorage

extension KVStores {
    struct AI {
        static let domain = Domain.biz.ai

        /// 构建 AI 业务用户无关的 `KVStore`
        static func global() -> KVStore {
            return KVStores.udkv(space: .global, domain: domain)
        }

        /// 构建 AI 业务用户相关的 `KVStore`
        static func user(id: String) -> KVStore {
            return KVStores.udkv(space: .user(id: id), domain: domain)
        }
    }
}

extension KVKeys {
    struct AI {
        // global scope
        static let smartCorrect = KVKey<[[String: String]]?>("smartCorrectDefaultesKey")
        static let webAutoTranslateGuide = KVKey("webAutoTranslateGuideKey", default: false)
        static let smartComposeKey = KVKey("smartComposeDefaultesKey", default: Int(0))
    }
}
