//
//  OpenPluginGetSystemInfoModel.swift
//  OPPlugin
//
//  Created by bytedance on 2021/4/20.
//

import Foundation
import LarkOpenAPIModel
import LKCommonsLogging
import LarkOpenPluginManager
private let logger = Logger.oplog(OpenPluginGetSystemInfoResult.self, category: "getSystemInfo")

final class OpenPluginGetSystemInfoNativeCardResult: OpenAPIBaseResult {
    let brand = "Apple"
    let model: String
    let pixelRatio = Float(UIScreen.main.scale)
    let language: String
    let version: String
    let system = "iOS \(UIDevice.current.systemVersion)"
    let appName: String
    let platform = "iOS"
    let battery: Int
    let wifiSignal :Int
    let theme: String?
    let geo: String?

    init(model: String, language: String, version: String, appName: String, battery: Int = 100, wifiSignal :Int = 4, theme: String? = nil, geo: String? = nil) {
        self.model = model
        self.language = language
        self.version = version
        self.appName = appName
        self.battery = battery
        self.wifiSignal = wifiSignal
        self.theme = theme
        self.geo = geo
        super.init()
    }
    
    override init() {
        model = ""
        language = ""
        version = ""
        appName = ""
        battery = 0
        wifiSignal = 0
        theme = nil
        geo = nil
        super.init()
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        var base: [String: Any] = [
                "brand": brand,
                "model": model,
                "pixelRatio": pixelRatio,
                "language": language,
                "version": version,
                "system": system,
                "appName": appName,
                "platform": platform,
                "battery": battery,
                "wifiSignal": wifiSignal
        ]
        
        base["theme"] = theme
        base["geo"] = geo
        
        return base
    }
}

final class OpenPluginGetSystemInfoResult: OpenAPIBaseResult {
    let commonInfo: OpenPluginGetSystemInfoNativeCardResult
    let screenWidth: Float
    let screenHeight: Float
    let windowWidth: Float
    let windowHeight: Float
    let statusBarHeight: Float
    let safeArea: GetSystemInfoSafeAreaRect
    let fontSizeSetting = 16
    let SDKVersion: String
    let SDKUpdateVersion: String
    let nativeSDKVersion = "2.46.0"
    let gadgetVersion: String
    let benchmarkLevel: Int
    let navigationBarSafeArea :GetSystemInfoSafeAreaRect?
    let blockitVersion: String?
    let packageVersion: String?
    let host: String?
    let pageOrientation: String?
    
    private var result: OpenPluginGetSystemInfoV2Result?
    private var extensionResult: OpenPluginGetSystemInfoExtensionResult?
    
    init(commonInfo: OpenPluginGetSystemInfoNativeCardResult) {
        self.commonInfo = commonInfo
        self.screenWidth = .zero
        self.screenHeight = .zero
        self.windowWidth = .zero
        self.windowHeight = .zero
        self.statusBarHeight = .zero
        self.safeArea = GetSystemInfoSafeAreaRect(left: .zero, right: .zero, top: .zero, bottom: .zero, width: .zero, height: .zero)
        self.SDKVersion = ""
        self.SDKUpdateVersion = ""
        self.gadgetVersion = ""
        self.benchmarkLevel = .zero
        self.navigationBarSafeArea = GetSystemInfoSafeAreaRect(left: .zero, right: .zero, top: .zero, bottom: .zero, width: .zero, height: .zero)
        self.blockitVersion = nil
        self.packageVersion = nil
        self.host = nil
        self.result = nil
        self.pageOrientation = nil
        super.init()
    }
    
    /// 临时使用的 init 方法
    /// 后续 OpenPluginDeviceFeatureKey.getSystemInfo 全量后
    /// OpenPluginGetSystemInfoV2Result 会是新的返回值
    convenience init(_ result: OpenPluginGetSystemInfoV2Result) {
        self.init()
        self.result = result
    }
    
    private override init() {
        self.commonInfo = OpenPluginGetSystemInfoNativeCardResult()
        self.screenWidth = .zero
        self.screenHeight = .zero
        self.windowWidth = .zero
        self.windowHeight = .zero
        self.statusBarHeight = .zero
        self.safeArea = GetSystemInfoSafeAreaRect(left: .zero, right: .zero, top: .zero, bottom: .zero, width: .zero, height: .zero)
        self.SDKVersion = ""
        self.SDKUpdateVersion = ""
        self.gadgetVersion = ""
        self.benchmarkLevel = .zero
        self.navigationBarSafeArea = GetSystemInfoSafeAreaRect(left: .zero, right: .zero, top: .zero, bottom: .zero, width: .zero, height: .zero)
        self.blockitVersion = nil
        self.packageVersion = nil
        self.host = nil
        self.pageOrientation = nil
        
        super.init()
    }
    
    convenience init(extensionResult: OpenPluginGetSystemInfoExtensionResult) {
        self.init()
        self.extensionResult = extensionResult
    }

    init(commonInfo: OpenPluginGetSystemInfoNativeCardResult, screenWidth: Float, screenHeight: Float, windowWidth: Float, windowHeight: Float, statusBarHeight: Float, safeArea: GetSystemInfoSafeAreaRect, SDKVersion: String, SDKUpdateVersion: String, gadgetVersion: String, benchmarkLevel: Int = 40, navigationBarSafeArea: GetSystemInfoSafeAreaRect?, blockitVersion: String?, packageVersion: String?, host: String?, pageOrientation: String?) {
        self.commonInfo = commonInfo
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.windowWidth = windowWidth
        self.windowHeight = windowHeight
        self.statusBarHeight = statusBarHeight
        self.safeArea = safeArea
        self.SDKVersion = SDKVersion
        self.SDKUpdateVersion = SDKUpdateVersion
        self.gadgetVersion = gadgetVersion
        self.benchmarkLevel = benchmarkLevel
        self.navigationBarSafeArea = navigationBarSafeArea
        self.blockitVersion = blockitVersion
        self.packageVersion = packageVersion
        self.host = host
        self.result = nil
        self.pageOrientation = pageOrientation
        super.init()
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        if let extensionResult {
            return extensionResult.toJSONDict()
        }
        let enable = OpenAPIFeatureKey.getSystemInfo.isEnable()
        if enable {
            if let result = result {
                return result.toJSONObject()
            } else {
                logger.error("getSystemInfo toJSON failure")
                assertionFailure()
                return [:]
            }
        }
        var json = [
            "statusBarHeight": statusBarHeight,
            "screenWidth": screenWidth,
            "screenHeight": screenHeight,
            "windowWidth": windowWidth,
            "windowHeight": windowHeight,
            "safeArea": safeArea.toJSONDict(), // obj
            "fontSizeSetting": fontSizeSetting,
            "SDKVersion": SDKVersion,
            "SDKUpdateVersion": SDKUpdateVersion,
            "nativeSDKVersion": nativeSDKVersion,
            "gadgetVersion": gadgetVersion,
            "benchmarkLevel": benchmarkLevel,
            "navigationBarSafeArea": navigationBarSafeArea?.toJSONDict() ?? "" // obj
        ].merging(commonInfo.toJSONDict()){$1} // obj
        if let blockitVersion = blockitVersion {
            json["blockitVersion"] = blockitVersion
        }
        if let packageVersion = packageVersion {
            json["packageVersion"] = packageVersion
        }
        if let host = host {
            json["host"] = host
        }

        if let pageOrientation = pageOrientation {
            json["pageOrientation"] = pageOrientation
        }
        return json
    }
}
