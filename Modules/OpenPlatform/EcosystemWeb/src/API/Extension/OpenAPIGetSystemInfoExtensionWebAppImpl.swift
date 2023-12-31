//
//  OpenAPIGetSystemInfoExtensionWebAppImpl.swift
//  EcosystemWeb
//
//  Created by baojianjun on 2023/8/15.
//

import Foundation
import OPFoundation
import TTMicroApp
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter

final class OpenAPIGetSystemInfoExtensionWebAppImpl: OpenAPIGetSystemInfoExtension, OpenAPIExtensionApp {
    let gadgetContext: GadgetAPIContext
    
    required init(extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        self.gadgetContext = try getGadgetContext(context)
        try super.init(extensionResolver: extensionResolver, context: context)
    }
    
    override func v1Disable() -> Bool {
        OpenAPIFeatureKey.getSystemInfo.isEnable()
    }
    
    override func currentWindowAndSize() -> (UIWindow?, CGSize) {
        let window = commonExtension.window()
        let windowSize = BDPResponderHelper.windowSize(window)
        return (window, windowSize)
    }
    
    override func statusBarHeight(safeAreaTop: Float) -> Float {
        return safeAreaTop == 0 ? 20 : safeAreaTop
    }
    
    override func pageOrientation() -> String? {
        nil
    }
    
    override func theme() -> String? {
        TTMicroApp.themeForUniqueID(uniqueID)
    }
    
    override func bizInfo() -> [String: String] {
        TTMicroApp.gadgetWebAppBizInfo(uniqueID: uniqueID)
    }
    
    override func viewInfo() -> [String: String] {
        // 小程序、网页应用的半屏信息
        var viewMode = "standard"
        var viewRatio = ""
        if let webBrowser = commonExtension.controller() as? OPContainerViewModeProtocol {
            viewMode = webBrowser.viewMode ?? "standard"
            viewRatio = webBrowser.viewRatio ?? ""
        }
        return [
            "viewMode": viewMode,
            "viewRatio": viewRatio,
        ]
    }
    
    override func tenantGeoKey() -> String? {
        uniqueID.appID
    }
}
