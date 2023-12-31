//
//  TTNetworkObjcBridge.swift
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/9.
//

import Foundation
import LKCommonsLogging
import LarkContainer

@objcMembers
@objc public final class TTNetworkObjcBridge: NSObject {
    
    static let logger = Logger.oplog(TTNetworkObjcBridge.self, category: "TTNetwork")
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue 
    }
    
    @objc public static func fetchNotice(by context: ECONetworkServiceContext, appID: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) {
        let locale = BDPLanguageHelper.appLanguage()
        let task = self.service.createTask(
            context: context,
            config: FetchNoticeByClientIDRequestConifg.self,
            params: ["locale":locale,
                     "client_id": appID],
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
