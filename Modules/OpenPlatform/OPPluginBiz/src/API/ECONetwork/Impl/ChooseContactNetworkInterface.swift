//
//  ChooseContactNetworkInterface.swift
//  EEMicroAppSDK
//
//  Created by xiangyuanyuan on 2021/11/15.
//

import Foundation
import LarkContainer
import LKCommonsLogging

public final class ChooseContactNetworkInterface {
    
    static let logger = Logger.oplog(ChooseContactNetworkInterface.self, category: "ECONetwork")
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }
    
    public static func getOpenDepartmentIDs(with context: ECONetworkServiceContext, parameters: [String: Any], completionHandler: @escaping ([String: Any]?, Error?) -> Void) {
        let task = Self.service.createTask(
            context: context,
            config: ChooseContactRequestConfig.self,
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
