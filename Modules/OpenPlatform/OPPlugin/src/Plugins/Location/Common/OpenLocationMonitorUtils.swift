//
//  OpenLocationMonitorUtils.swift
//  OPPlugin
//
//  Created by zhangxudong on 4/14/22.
//

import Foundation
import OPSDK
import LarkOpenAPIModel
import OPFoundation

struct OpenLocationMonitorUtils {
    /// meego: https://meego.feishu.cn/larksuite/story/detail/4661196
    /// location相关API 对输入参数 坐标系type 进行埋点
    static func report(apiName: String, locationType: String,  context: OpenAPIContext) {
        guard let gadgetContext = context.gadgetContext else {
            assertionFailure("gadgetContext can not be nil")
            return
        }

        let uniqueID = gadgetContext.uniqueID
        let appID = uniqueID.appID
        let appType = OPAppTypeToString(uniqueID.appType)

        context.apiTrace.info("monitor report 'openplatform_client_api_location_type_show' apiName:\(apiName) locationType\(locationType)) appID:\(appID) appType:\(appType) location")
        /// 埋点设计 https://bytedance.sg.feishu.cn/sheets/shtlg9007tJlNuGBP5Dj4POtFUe?useNewLarklet=1
        OPMonitor("openplatform_client_api_location_type_show")
            .addCategoryValue("application_id", appID)
            .addCategoryValue("api_name", apiName)
            .addCategoryValue("location_type", locationType)
            .addCategoryValue("app_origin_type", appType)
            .setPlatform(.tea)
            .flush()
    }
}
