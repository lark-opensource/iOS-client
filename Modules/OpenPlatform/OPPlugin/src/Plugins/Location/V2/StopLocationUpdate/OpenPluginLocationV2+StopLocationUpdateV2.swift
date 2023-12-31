//
//  OpenPluginLocation+StopLocationUpdateV2.swift
//  OPPlugin
//
//  Created by zhangxudong on 4/21/22.
//

import OPSDK
import LarkOpenAPIModel
import LarkOpenPluginManager

extension OpenPluginLocationV2 {
    /// stopLocationUpdate 合规版本实现
    public func stopLocationUpdateV2(params: OpenAPIBaseParams,
                                     context: OpenAPIContext,
                                     callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("stopLocationUpdateV2 enter")
        guard let uniqueID = context.uniqueID else {
            context.apiTrace.error("gadgetContext is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("gadgetContext is nil")
            callback(.failure(error: error))
            return
        }
        if let task = continueLocationTask(for: uniqueID) {
            context.apiTrace.info("continueLocationTask taskID: \(task.taskID) stopLocaitonUpdate")
            task.stopLocationUpdate()
        } else {
            context.apiTrace.info("continueLocationTask is nil")
        }
        /// 删除用户stop的task
        deleteContinueLocationTask(for: uniqueID)
        callback(.success(data: nil))
    }
}

