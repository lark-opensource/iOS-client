//
//  OpenAPIGetSystemInfoExtensionNativeAppImpl.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/11/7.
//

import Foundation
import OPFoundation
import TTMicroApp
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter

let getGadgetContext: (OpenAPIContext) throws -> GadgetAPIContext = { context in
    guard let gadgetContext = context.gadgetContext as? GadgetAPIContext else {
        throw OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage("gadgetContext is nil")
            .setErrno(OpenAPICommonErrno.unknown)
    }
    return gadgetContext
}

final class OpenAPIGetSystemInfoExtensionNativeAppImpl: OpenAPIGetSystemInfoExtension, OpenAPIExtensionApp {
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
        return OPGadgetRotationHelper.configPageInterfaceResponse(UIApplication.shared.statusBarOrientation)
    }
    
    override func theme() -> String? {
        TTMicroApp.themeForUniqueID(uniqueID)
    }
    
    override func bizInfo() -> [String: String] {
        TTMicroApp.gadgetWebAppBizInfo(uniqueID: uniqueID)
    }
    
    override func viewInfo() -> [String: String] {
        return [
            "viewMode": "standard",
            "viewRatio": "",
        ]
    }
    
    override func tenantGeoKey() -> String? {
        uniqueID.appID
    }
}
