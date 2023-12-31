//
//  OpenAPIBizExtension.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/6/7.
//

import Foundation
import ECOProbe
import ECOInfra

open class OpenAPIMonitorReportExtension: OpenBaseExtension {
    open func apiDisable() -> Bool { false }
    
    @OpenAPIRequiredExtension
    public var commonExtension: OpenAPICommonExtension
    
    public override var autoCheckProperties: [OpenAPIInjectExtension] {
        [_commonExtension]
    }
}


open class OpenAPIWifiExtension: OpenBaseExtension {
    open func addAppIdInfo(in monitor: OPMonitor) {
        
    }
}


open class OpenAPIGetSystemInfoExtension: OpenBaseExtension {
    
    open func v1Disable() -> Bool { false }
    
    open func currentWindowAndSize() -> (UIWindow?, CGSize) { (nil, .zero) }
    
    open func statusBarHeight(safeAreaTop: Float) -> Float { 0 }
    
    open func navigationBarSafeArea() -> GetSystemInfoSafeAreaRect? { nil }
    
    open func pageOrientation() -> String? { nil }
    
    open func theme() -> String? { nil }
    
    open func bizInfo() -> [String: String] { [:] }
    
    open func viewInfo() -> [String: String] { [:] }
    
    open func tenantGeoKey() -> String? { nil }
    
    @OpenAPIRequiredExtension
    public var commonExtension: OpenAPICommonExtension
    
    override public var autoCheckProperties: [OpenAPIInjectExtension] {
        [_commonExtension]
    }
}

public final class GetSystemInfoSafeAreaRect {
    let left: Float
    let right: Float
    public let top: Float
    let bottom: Float
    let width: Float
    let height: Float
    
    public init(left: Float, right: Float, top: Float, bottom: Float, width: Float, height: Float) {
        self.left = left
        self.right = right
        self.top = top
        self.bottom = bottom
        self.width = width
        self.height = height
    }

    public func toJSONDict() -> [AnyHashable : Any] {
        [
            "left": left,
            "right": right,
            "top": top,
            "bottom": bottom,
            "width": width,
            "height": height
        ]
    }
}
