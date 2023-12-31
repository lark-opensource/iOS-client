//
//  AdvertisingStorage.swift
//  LarkTour
//
//  Created by Meng on 2020/4/17.
//

import Foundation
import LarkStorage

enum InstallConfigKey {
    static let launchGuideKey: String = "launch_guide_key"
    static let loginPatternKey: String = "login_pattern"
}

enum RegParamsKey {
    static let ugSourceKey: String = "ug_source"
}

final class AdvertisingStorage {
    private let _store = KVStores.udkv(space: .global, domain: Domain.biz.core.child("UserGrowth"))
    private static let store = \AdvertisingStorage._store

    @KVBinding(to: store, key: "ad_install_source", default: "")
    var installSource: String

    @KVBinding(to: store, key: "ad_user_source", default: "")
    var userSource: String

    @KVBinding(to: store, key: "ad_install_source_config", default: [:])
    var installConfig: [String: String]

    var hasInstallSource: Bool {
        return !installSource.isEmpty
    }

    var hasUserSource: Bool {
        return !userSource.isEmpty
    }
}
