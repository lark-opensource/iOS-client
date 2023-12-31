//
//  KVStorge.swift
//  LarkSetting
//
//  Created by 王元洵 on 2023/3/29.
//

import LarkStorage

extension KVStores {
    enum FG {
        static let domain = Domain.biz.infra.child("FeatureGating")

        /// 构建 FG 业务用户无关的 `KVStore`
        static var global: KVStore { KVStores.udkv(space: .global, domain: domain) }

        /// 构建 FG 业务用户相关的 `KVStore`
        static func user(id: String) -> KVStore { KVStores.udkv(space: .user(id: id), domain: domain) }
    }
}
