//
//  OpenPluginSystemInfoResult.swift
//  OPPlugin
//
//  Created by 王飞 on 2022/3/22.
//

import OPPluginManagerAdapter
import OPFoundation
import LarkOpenAPIModel
import LarkOpenPluginManager

/// 目前的一切返回值需要 toJSONDic
/// 直接用 Codable 转成 Data 并不适用，需要底层框架做支持
/// 否则会进行 model to data to dic 这样的无用功，所以暂时全使用 dic
/// 后续底层支持后逐渐迁移到 Codable 上面去
/// OpenAPIJSONDict 还是个 objc 的 protocol，后面得兼容下

/// 仅提供给 getSystemInfo 接口使用，这里就是为了约束下方法名
protocol OpenPluginDeviceJSONObject {
    func toJSONObject() -> [AnyHashable : Any]
}

struct OpenPluginDeviceUIInfo: OpenPluginDeviceJSONObject {
    func toJSONObject() -> [AnyHashable : Any] {
        var result: [String : Any] = [
            "statusBarHeight": statusBarHeight,
            "screenWidth": screenWidth,
            "screenHeight": screenHeight,
            "windowWidth": windowWidth,
            "windowHeight": windowHeight,
            "fontSizeSetting": fontSizeSetting,
            "safeArea": safeArea.toJSONDict()
        ]
        if let theme = theme {
            result["theme"] = theme
        }
        if let navigationBarSafeArea = navigationBarSafeArea {
            result["navigationBarSafeArea"] = navigationBarSafeArea.toJSONDict()
        }

        if let pageOrientation = pageOrientation {
            result["pageOrientation"] = pageOrientation
        }
        
        return result
    }
    
    public let screenWidth: Float
    public let screenHeight: Float
    public let windowWidth: Float
    public let windowHeight: Float
    public let statusBarHeight: Float
    /// 这里看起来是固定的啊
    public let fontSizeSetting = 16
    public let theme: String?
    public let safeArea: GetSystemInfoSafeAreaRect
    /// 如果未设置“自定义导航栏”，则不返回该字段
    public let navigationBarSafeArea :GetSystemInfoSafeAreaRect?
    /// 页面方向, 如果FG关闭则不返回.
    public let pageOrientation: String?
}

struct OpenPluginDeviceCommonInfo: OpenPluginDeviceJSONObject {
    func toJSONObject() -> [AnyHashable : Any] {
        var result: [String: Any] = [
            "brand": brand,
            "model": model,
            "pixelRatio": pixelRatio,
            "language": language,
            "version": version,
            "system": system,
            "appName": appName,
            "platform": platform
        ]
        
        result["geo"] = geo
        
        return result
    }
    
    public let brand = "Apple"
    public let model = OPUnsafeObject(BDPDeviceHelper.getDeviceName()) ?? ""
    public let pixelRatio = Float(UIScreen.main.scale)
    public let language = BDPApplicationManager.language() ?? ""
    public let version = BDPDeviceTool.bundleShortVersion ?? ""
    public let system = "iOS \(UIDevice.current.systemVersion)"
    public let appName = BDPApplicationManager.shared().applicationInfo[BDPAppNameKey] as? String ?? ""
    public let platform = "iOS"
    public var geo: String? = nil
}

struct OpenPluginGadgetAndWebInfo: OpenPluginDeviceJSONObject {
    func toJSONObject() -> [AnyHashable : Any] {
        [
            "gadgetVersion": gadgetVersion,
            "SDKVersion": sdkVersion,
            "SDKUpdateVersion": sdkUpdateVersion,
            "viewMode": viewMode,
            "viewRatio": viewRatio,
        ]
    }
    
    // 目前有大量开发者强依赖，所以保留
    public let gadgetVersion: String
    public let sdkVersion: String
    public let sdkUpdateVersion: String
    public let viewMode: String
    public let viewRatio: String
}

struct OpenPluginBlockInfo: OpenPluginDeviceJSONObject {
    func toJSONObject() -> [AnyHashable : Any] {
        [
            "blockitVersion": blockitVersion,
            "packageVersion": packageVersion,
            "host": host,
        ]
    }
    
    public let blockitVersion: String
    public let packageVersion: String
    public let host: String
}

struct OpenPluginGetSystemInfoV2Result: OpenPluginDeviceJSONObject {
    func toJSONObject() -> [AnyHashable : Any] {
        var result = ui.toJSONObject().merging(common.toJSONObject()) {$1}
        if let block = block {
            result.merge(block.toJSONObject()) {$1}
        }
        if let gadgetAndWeb = gadgetAndWeb {
            result.merge(gadgetAndWeb.toJSONObject()) {$1}
        }
        result["tenantGeo"] = tenantGeo
        return result
    }
    
    public let common: OpenPluginDeviceCommonInfo
    public let ui: OpenPluginDeviceUIInfo
    public let gadgetAndWeb: OpenPluginGadgetAndWebInfo?
    public let block: OpenPluginBlockInfo?

    /// description: 租户 Geo 信息
    public let tenantGeo: String?
}
