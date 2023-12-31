//
//  APIExtensionFGHelper.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/20.
//

import Foundation

@testable import LarkSetting

@available(iOS 13.0, *)
public class APIExtensionFGHelper {
    
    private static let extensionKey = "openplatform.api.pluginmanager.extension.enable"
    
    public static func enableExtension() {
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.extensionKey, isEnable: true, id: "")
    }

    public static func disableExtension() {
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.extensionKey, isEnable: false, id: "")
    }
}


@available(iOS 13.0, *)
public class APIExtensionFGHelper7_1 {
    
    private static let extensionKey = "openplatform.api.extension.decouple.with.ttmicro"
    
    public static func enableExtension() {
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.extensionKey, isEnable: true, id: "")
    }

    public static func disableExtension() {
        FeatureGatingStorage.updateDebugFeatureGating(fg: Self.extensionKey, isEnable: false, id: "")
    }
}
