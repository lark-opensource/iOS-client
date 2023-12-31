//
//  OpenPluginStatusBar.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/10/1.
//

import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkContainer

final class StatusBarPlugin: OpenBasePlugin {
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        /// PRD: https://bytedance.feishu.cn/docs/doccnSK0Nxc4fkp5uRCPGy9jG4d
        /// 按照API组规范，iOS即使无法修改状态栏颜色，也必须对等的加上一个API，避免前端写if 安卓 else if iOS的代码
        registerAsyncHandler(for: "setStatusBarColor") { (params, context, callback) in
            let msg = "iOS system not support customize status bar color"
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
            context.apiTrace.error(msg)
            callback(.failure(error: error))
        }
    }
}
