//
//  UserDaults+Extension.swift
//  LarkCache
//
//  Created by Supeng on 2020/8/24.
//

import Foundation
import LarkStorage

struct CleanRecord: Codable, KVNonOptional {
    var date: TimeInterval
    var times: Int
}

struct KVStates {
    static let store = KVStores
        .udkv(space: .global, domain: Domain.biz.infra.child("LarkCache"))
        .simplified()
        .usingMigration(config: .from(userDefaults: .standard, items: [
            "lark.cache.manager.larst_clean_time" ~> "last_clean_time",
            "lark.cache.manager.clean_record" ~> "clean_record",
            "lark.cache.manager.cache_path_to_clean_identifier_map" ~> "cache_path_to_clean_identifier_map"
        ]))

    @KVConfig(key: "last_clean_time", store: store)
    static var lastCleanTime: TimeInterval?


    @KVConfig(key: "clean_record", store: store)
    static var cleanRecord: CleanRecord?

    @KVConfig(key: "cache_path_to_clean_identifier_map", default: [:], store: store)
    static var cachePathToCleanIdentifierMap: [String: String]
}
