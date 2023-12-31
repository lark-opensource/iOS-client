//
//  SyncAppReviewNetworkInterface.swift
//  TTMicroApp
//
//  Created by xiangyuanyuan on 2021/12/20.
//

import Foundation
import LKCommonsLogging
import LarkContainer
import OPFoundation

final class SyncAppReviewNetworkInterface {
    
    static let logger = Logger.oplog(SyncAppReviewNetworkInterface.self, category: "AppReview")
    
    @Provider private static var service: ECONetworkService
    
    public static func syncAppReview(
        with context: ECONetworkServiceContext,
        parameters: [String: String]?,
        completionHandler: @escaping ([String: Any]?, Error?) -> Void
    ) {
        let task = Self.service.createTask(
            context: context,
            config: SyncAppReviewRequestConfig.self,
            params:  parameters,
            callbackQueue: DispatchQueue.main
        ) { (response, error) in
            completionHandler(response?.result, error)
        }
        guard let requestTask = task else {
            assertionFailure("create task fail")
            Self.logger.error("create task fail \(context.getTrace().traceId)")
            let opError = OPError.error(monitorCode: CommonMonitorCode.fail)
            completionHandler(nil, opError)
            return
        }
        service.resume(task: requestTask)
    }
}
