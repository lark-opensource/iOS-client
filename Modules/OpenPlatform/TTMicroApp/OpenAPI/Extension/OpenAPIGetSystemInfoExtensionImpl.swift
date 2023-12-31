//
//  OpenAPIGetSystemInfoExtensionImpl.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/6/10.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import UniverseDesignTheme
import OPPluginManagerAdapter

public func themeForUniqueID(_ uniuqeID: OPAppUniqueID) -> String? {
    guard uniuqeID.isAppSupportDarkMode else {
        return nil
    }
    if #available(iOS 13.0, *) {
        switch UDThemeManager.getRealUserInterfaceStyle() {
        case .light:
            return OPThemeValueLight
        case .dark:
            return OPThemeValueDark
        default:
            return nil
        }
    } else {
        return nil
    }
}

/// copy from `func gadgetAndWebInfo(uniqueID: OPAppUniqueID, gadgetContext: OPAPIContextProtocol) -> OpenPluginGadgetAndWebInfo?`
public func gadgetWebAppBizInfo(uniqueID: OPAppUniqueID) -> [String: String] {
    let common = BDPCommonManager.shared().getCommonWith(uniqueID)
    let sdkVersion = common?.sdkVersion ?? BDPVersionManager.localLibBaseVersionString() ?? ""
    let sdkUpdateVersion =  common?.sdkUpdateVersion ?? BDPVersionManager.localLibVersionString() ?? ""
    let gadgetVersion = common?.model.version ?? ""
    
    return [
        "gadgetVersion": gadgetVersion,
        "SDKVersion": sdkVersion,
        "SDKUpdateVersion": sdkUpdateVersion,
    ]
}

func tenantGeoKey(uniqueID: OPAppUniqueID) -> String? {
    uniqueID.appID
}

final class OpenAPIGetSystemInfoExtensionGadgetImpl: OpenAPIGetSystemInfoExtension, OpenAPIExtensionApp {
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
        let container = BDPModuleManager(of: .gadget).resolveModule(with: BDPContainerModuleProtocol.self) as? BDPContainerModuleProtocol
        let windowSize = container?.containerSize(commonExtension.controller(), type: .gadget, uniqueID: uniqueID) ?? .zero
        return (window, windowSize)
    }
    
    override func statusBarHeight(safeAreaTop: Float) -> Float {
        var statusBarHeight = safeAreaTop == 0 ? 20 : safeAreaTop
        // FG关闭时, 返回原逻辑的值
        guard OPGadgetRotationHelper.enableResponseOrientationInfo() else {
            return statusBarHeight
        }

        if let appController = commonExtension.controller() as? BDPAppController,
           let appPageController = appController.currentAppPage() {
            if appPageController.pageInterfaceOrientation == .landscapeLeft
                || appPageController.pageInterfaceOrientation == .landscapeRight {
                statusBarHeight = 0
            }
        }
        return statusBarHeight
    }
    
    override func navigationBarSafeArea() -> GetSystemInfoSafeAreaRect? {
        let naviBarSafeArea = BDPAppController
            .currentAppPageController(commonExtension.controller(), fixForPopover: false)?
            .getNavigationBarSafeArea()
        if let naviBarSafeAreaObject = naviBarSafeArea {
            return GetSystemInfoSafeAreaRect(left:Float(naviBarSafeAreaObject.left),
                                             right: Float(naviBarSafeAreaObject.right),
                                             top: Float(naviBarSafeAreaObject.top),
                                             bottom: Float(naviBarSafeAreaObject.bottom),
                                             width: Float(naviBarSafeAreaObject.width),
                                             height: Float(naviBarSafeAreaObject.height))
        }
        return nil
    }
    
    override func pageOrientation() -> String? {
        guard OPGadgetRotationHelper.enableResponseOrientationInfo() else {
            return nil
        }

        var pageOrientation: String?
        if let appController = commonExtension.controller() as? BDPAppController,
           let appPageController = appController.currentAppPage() {
            pageOrientation = OPGadgetRotationHelper.configPageInterfaceResponse(appPageController.pageInterfaceOrientation)
        }

        return pageOrientation
    }
    
    override func theme() -> String? {
        themeForUniqueID(uniqueID)
    }
    
    override func bizInfo() -> [String: String] {
        gadgetWebAppBizInfo(uniqueID: uniqueID)
    }
    
    override func viewInfo() -> [String: String] {
        // 小程序、网页应用的半屏信息
        var viewMode = "standard"
        var viewRatio = ""
        if BDPXScreenManager.isXScreenMode(uniqueID) {
            viewMode = "panel"
            viewRatio = BDPXScreenManager.xScreenPresentationStyle(uniqueID) ?? ""
        }
        return [
            "viewMode": viewMode,
            "viewRatio": viewRatio,
        ]
    }
    
    override func tenantGeoKey() -> String? {
        TTMicroApp.tenantGeoKey(uniqueID: uniqueID)
    }
}

final class OpenAPIGetSystemInfoExtensionBlockImpl: OpenAPIGetSystemInfoExtension, OpenAPIExtensionApp {
    let gadgetContext: GadgetAPIContext
    
    required init(extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        self.gadgetContext = try getGadgetContext(context)
        try super.init(extensionResolver: extensionResolver, context: context)
    }
    
    override func v1Disable() -> Bool {
        OpenAPIFeatureKey.getSystemInfo.isEnable()
    }
    
    override func currentWindowAndSize() -> (UIWindow?, CGSize) {
        let windowSize = BDPResponderHelper.windowSize(nil)
        return (nil, windowSize)
    }
    
    override func statusBarHeight(safeAreaTop: Float) -> Float {
        safeAreaTop == 0 ? 20 : safeAreaTop
    }
    
    override func pageOrientation() -> String? { nil }
    
    override func theme() -> String? {
        themeForUniqueID(uniqueID)
    }
    
    override func bizInfo() -> [String: String] {
        let blockitSDKVersion = uniqueID.runtimeVersion ?? ""
        let packageVersion = uniqueID.packageVersion ?? ""
        let host = uniqueID.host
        return [
            "blockitVersion": blockitSDKVersion,
            "packageVersion": packageVersion,
            "host": host,
        ]
    }
    
    override func viewInfo() -> [String: String] {
        [
            "viewMode": "standard",
            "viewRatio": "",
        ]
    }
    
    override func tenantGeoKey() -> String? {
        TTMicroApp.tenantGeoKey(uniqueID: uniqueID)
    }
}
