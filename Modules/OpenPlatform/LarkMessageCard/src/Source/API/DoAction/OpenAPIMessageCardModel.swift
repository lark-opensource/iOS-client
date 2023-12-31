//
//  OpenAPIMessageCardModel.swift
//  LarkOpenAPIModel
//
//  Created by zhangjie.alonso on 2023/2/7.
//

import Foundation
import LarkOpenAPIModel

 enum MsgCardActionResult: String {
    case fail = "fail"
    case success = "finishedWaitUpdate"
    
}
 enum MsgCardActionResultCode: Int {
    //fail 用户conform取消，回调上报
    case userCancel = 1
    //success 用户conform确认执行及无conform直接执行，回调上报
    case success = 0
}


final class OpenAPIMessageCardResult: OpenAPIBaseResult {

    private var messageCardResult:[AnyHashable : Any]
    
     init(_ result: MsgCardActionResult, resultCode: MsgCardActionResultCode) {
        messageCardResult = ["result": result.rawValue]
        messageCardResult["code"] = resultCode.rawValue
        super.init()
    }

     override func toJSONDict() -> [AnyHashable : Any] {
        return messageCardResult
    }
}
