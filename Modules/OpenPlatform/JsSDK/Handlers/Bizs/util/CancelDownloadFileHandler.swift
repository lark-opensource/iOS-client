//
//  CancelDownloadFileHandler.swift
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/9/25.
//

import LKCommonsLogging
import WebBrowser

/// 取消正在进行的下载任务
class CancelDownloadFileHandler: JsAPIHandler {

    static let logger = Logger.log(CancelDownloadFileHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let taskId = args["taskId"] as? String,
            let request = sdk.downloadRequests[taskId] else {
                /// 取消任务没有对应的taskID或者taskID找不到对应的request
                CancelDownloadFileHandler.logger.log(level: .error, "取消任务没有对应的taskID或者taskID找不到对应的request")
                return
        }
        request.cancel()
    }
}
