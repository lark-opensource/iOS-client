//
//  OpenAPIGetConnectedWifiMonitor.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/18/22.
//

import ECOProbeMeta
import ECOProbe
import OPPluginManagerAdapter
import OPSDK
import LarkOpenAPIModel
/// getConnectedWifi API 监控
struct OpenAPIGetConnectedWifiMonitor {
    let monitor = OPMonitor(EPMClientOpenPlatformApiWifiCode.get_connected_wifi)
        .addCategoryValue("systemVersion", UIDevice.current.systemVersion)

    enum Tool: String {
        case cache = "cache"
        case NEHotspotNetworkFetchCurrent = "NEHotspotNetwork.fetchCurrent"
        case NEHotspotHelperSupportedNetworkInterfaces = "NEHotspotHelper.supportedNetworkInterfaces"
        case CNCopySupportedInterfaces = "CNCopySupportedInterfaces"
    }
    enum FailedReason: String {
        case noLocationAuthorization = "noLocationAuthorization"
        case noConnectedWifi = "noConnectedWifi"
        case unknow = "unknow"
    }
    /// 上报获取wifi使用的工具
    @discardableResult
    func set(tool: Tool) -> Self {
        monitor.addCategoryValue("tool", tool.rawValue)
        return self
    }
    /// 上报成功状态
    @discardableResult
    func reportSuccess() -> Self {
        monitor.setResultTypeSuccess().flush()
        return self
    }
    /// 上报失败原因
    @discardableResult
    func reportFailed(reason: FailedReason) -> Self {
        monitor.addCategoryValue("failedReason", reason.rawValue)
            .setResultTypeFail().flush()
        return self
    }
    /// 上报OpenAPIContext 通用信息
    func set(_ wifiExtension: OpenAPIWifiExtension?) {
        wifiExtension?.addAppIdInfo(in: monitor)
    }
    
    @discardableResult
    func set(context: OpenAPIContext) -> Self {
        guard let gadgetContext = context.additionalInfo["gadgetContext"] as? GadgetAPIContext else {
            return self
        }
        let uniqueID = gadgetContext.uniqueID
        monitor.addCategoryValue("appID", uniqueID.appID)
        monitor.addCategoryValue("appType", OPAppTypeToString(uniqueID.appType))
        return self
    }

  
}
