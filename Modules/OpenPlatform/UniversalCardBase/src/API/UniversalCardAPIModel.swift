//
//  UniversalCardAPIModel.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/8/10.
//

import Foundation
import LarkOpenAPIModel

enum UniversalCardActionResult: String {
   case fail = "fail"
   case success = "success"

}
enum UniversalCardActionResultCode: Int {
   //fail 用户conform取消，回调上报
   case userCancel = 1
   //success 用户conform确认执行及无conform直接执行，回调上报
   case success = 0
}


final class OpenAPIUniversalCardResult: OpenAPIBaseResult {

   private var smartCardResult:[AnyHashable : Any]

    init(_ result: UniversalCardActionResult, resultCode: UniversalCardActionResultCode) {
        smartCardResult = ["result": result.rawValue]
        smartCardResult["code"] = resultCode.rawValue
       super.init()
   }

    override func toJSONDict() -> [AnyHashable : Any] {
       return smartCardResult
   }
}
