//
//  OPPluginContact+ECONetwork+Mock.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/10/9.
//

import Foundation
import OCMock

import OPUnitTestFoundation
import OPFoundation
import LarkContainer
@testable import LarkSetting

struct OPAPIUniteOptFGMock {
    static let key = "openplatform.open.interface.api.unite.opt"
    
    static func enableUniteOpt() {
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.key, isEnable: true, id: UserStorageManager.placeholderUserID)
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.key, isEnable: true, id: "")
    }
    static func disableUniteOpt() {
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.key, isEnable: false, id: UserStorageManager.placeholderUserID)
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.key, isEnable: false, id: "")
    }
}

struct OPAPIEMARouteProviderFGMock {
    static let key = "openplatform.architecture.eeroute.decoupling"
    
    static func enableProviderOpt() {
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.key, isEnable: true, id: UserStorageManager.placeholderUserID)
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.key, isEnable: true, id: "")
    }
    static func disableProviderOpt() {
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.key, isEnable: false, id: UserStorageManager.placeholderUserID)
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.key, isEnable: false, id: "")
    }
}
