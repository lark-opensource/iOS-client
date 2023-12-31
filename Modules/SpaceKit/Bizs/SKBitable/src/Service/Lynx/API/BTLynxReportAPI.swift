//
//  BTLynxReportAPI.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/8.
//

import Foundation
import SKFoundation
import LarkLynxKit
import BDXLynxKit

public final class BTLynxReportAPI: NSObject, BTLynxAPI {
    static let apiName = "report"
    /**
     调用OpenAPI

     - Parameters:
       - apiName: API名
       - params: 调用API时的入参
       - callback: Lynx JSBridge回调
     */
    func invoke(params: [AnyHashable : Any],
                lynxContext: LynxContext?,
                bizContext: LynxContainerContext?,
                callback:  BTLynxAPICallback<BTLynxAPIBaseResult>?) {
        guard let eventName = params["eventName"] as? String else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "eventName")))
            return
        }
        DocsTracker.newLog(event: eventName, parameters: params)
        callback?(.success(data: BTLynxAPIBaseResult()))
    }
}
