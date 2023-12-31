//
//  OpenPluginGetSystemInfoExtension.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/6/27.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import LarkOpenPluginManager

struct OpenPluginGetSystemInfoExtensionResult {
    func toJSONDict() -> [AnyHashable : Any] {
        var result = ui.toJSONObject().merging(common.toJSONObject()) {$1}
        result.merge(bizInfo) {$1}
        result.merge(viewInfo) {$1}
        result["tenantGeo"] = tenantGeo
        return result
    }
    
    let common: OpenPluginDeviceCommonInfo
    let ui: OpenPluginDeviceUIInfo
    let bizInfo: [String: String]
    let viewInfo: [String: String]

    /// description: 租户 Geo 信息
    let tenantGeo: String?
}

extension OpenPluginGetSystemInfo {
    // 对 getSystemInfoV2进行extension拆解
    func getSystemInfoExtension(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        getSystemInfoExtension: OpenAPIGetSystemInfoExtension
    ) -> OpenAPIBaseResponse<OpenPluginGetSystemInfoResult> {
        
        context.apiTrace.info("getSystemInfoExtension begin")
        
        var common = OpenPluginDeviceCommonInfo()
        
        let ui = pr_UIModel(getSystemInfoExtension)
        
        let bizInfo = getSystemInfoExtension.bizInfo()
        
        let viewInfo = getSystemInfoExtension.viewInfo()
        
        // geo 和 getTenantGeo 保留原逻辑, 由extension提供查询key
        var tenantGeo: String?
        if let key = getSystemInfoExtension.tenantGeoKey() {
            do {
                common.geo = try geoInfoForAppID(key, trace: context.apiTrace)
                tenantGeo = try getTenantGeo(appId: key, trace: context.apiTrace)
            } catch let error as OpenAPIError {
                return .failure(error: error)
            } catch {
                return .failure(error: OpenAPIError(errno: OpenAPICommonErrno.unknown).setMonitorMessage("geo or tenant geo unknown error"))
            }
        }
        
        let result = OpenPluginGetSystemInfoExtensionResult(
            common: common,
            ui: ui,
            bizInfo: bizInfo,
            viewInfo: viewInfo,
            tenantGeo: tenantGeo
        )
        context.apiTrace.info("getSystemInfoExtension success")
        return .success(data: .init(extensionResult: result))
    }
    
    /// 全部 UI 信息
    /// - Parameter gadgetContext: 当前 API 运行容器的上下文环境
    /// - Returns: UI 信息
    func pr_UIModel(_ getSystemInfoExtension: OpenAPIGetSystemInfoExtension) -> OpenPluginDeviceUIInfo {
        
        let (window, windowSize) = getSystemInfoExtension.currentWindowAndSize()
        
        let safeArea = currentSafeArea(forWindow: window, windowSize: windowSize)
        
        let windowWidth = Float(windowSize.width)
        let windowHeight = Float(windowSize.height)
        let screenWidth = Float(UIScreen.main.bounds.size.width)
        let screenHeight = Float(UIScreen.main.bounds.size.height)
        
        let statusBarHeight = getSystemInfoExtension.statusBarHeight(safeAreaTop: safeArea.top)
        
        let naviSafeArea = getSystemInfoExtension.navigationBarSafeArea()
        
        // 页面方向
        let pageOrientation = getSystemInfoExtension.pageOrientation()
        
        let theme = getSystemInfoExtension.theme()

        return .init(screenWidth: screenWidth,
                     screenHeight: screenHeight,
                     windowWidth: windowWidth,
                     windowHeight: windowHeight,
                     statusBarHeight: statusBarHeight,
                     theme: theme,
                     safeArea: safeArea,
                     navigationBarSafeArea: naviSafeArea,
                     pageOrientation: pageOrientation)
    }
    
}
