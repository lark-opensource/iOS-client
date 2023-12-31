//
//  FetchUserIDsByOpenIDsRequestConfig.swift
//  EEMicroAppSDK
//
//  Created by MJXin on 2021/6/8.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import ECOInfra
import OPFoundation

public final class EMANetworkObjcBridge: NSObject {
    
    static let logger = Logger.oplog(EMANetworkObjcBridge.self, category: "ECONetwork")
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }
    
    public static func fetchChatIDByOpenChatIDs(with context: ECONetworkServiceContext, openChatIDs: [String], completionHandler: @escaping ([String: Any]?, Error?) -> Void) {
        let task = Self.service.createTask( 
            context: context,
            config: FetchChatIDByOpenChatIDsRequestConfig.self,
            params: ["open_chatids": openChatIDs],
            callbackQueue: DispatchQueue.main
        ) { (response, error) in
            completionHandler(response?.result, error)
        }
        guard let requestTask = task else {
            assertionFailure("create task fail")
            Self.logger.error("create task fail \(context.getTrace().traceId)")
            return
        }
        service.resume(task: requestTask)
    }
}
