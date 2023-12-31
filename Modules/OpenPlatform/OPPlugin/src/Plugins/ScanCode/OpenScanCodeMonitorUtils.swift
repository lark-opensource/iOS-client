//
//  OpenScanCodeMonitorUtils.swift
//  OPPlugin
//
//  Created by ByteDance on 2022/9/6.
//

import Foundation
import OPSDK
import LarkOpenPluginManager
import OPFoundation
import LarkOpenAPIModel

struct OpenScanCodeMonitorUtils {
  /// [需求文档] https://bytedance.feishu.cn/docx/doxcn9hV03m7n9VQug3Ff42vOHd
  /// scanCode API 埋点，场景：移动端有调用scanCode客户端API，发起请求的时候上报 https://bytedance.sg.feishu.cn/sheets/shtlg58cqbWodypxPFOHV9xBGPd
    static func report(scanType: [String], context: OpenAPIContext) {
        guard let gadgetContext = context.gadgetContext else {
          assertionFailure("gadgetContext can not be nil")
          return
        }

        let uniqueID = gadgetContext.uniqueID
        let appID = uniqueID.appID
        let appType = OPAppTypeToString(uniqueID.appType)
        let scanTypeStr = tranformScanType(scanType: scanType)
        let hasScanTypeStr = (scanType.count != 0) ? "true" : "false"
        
        context.apiTrace.info("monitor report 'openplatform_client_api_scancode_scantype_show' hasScanTypeParams:\(hasScanTypeStr) scanType:\(scanTypeStr) appID:\(appID) appType:\(appType)")
        OPMonitor("openplatform_client_api_scancode_scantype_show")
          .addCategoryValue("application_id", appID)
          .addCategoryValue("app_type", appType)
          .addCategoryValue("if_input_scan_type", hasScanTypeStr)
          .addCategoryValue("scan_type", scanTypeStr)
          .setPlatform(.tea)
          .flush()
    }
    
    static func tranformScanType(scanType: [String]) -> String {
        var scanTypes:[String] = []
        if scanType.contains("qrCode") {
            scanTypes.append("qr_code")
        }
        if scanType.contains("barCode") {
            scanTypes.append("bar_code")
        }
        if scanType.contains("datamatrix") {
            scanTypes.append("datamatrix")
        }
        if scanType.contains("pdf417") {
            scanTypes.append("pdf417")
        }
        let str = scanTypes.joined(separator: ",")
        return str
    }
}
