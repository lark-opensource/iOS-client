//
//  WKWebview+Lark.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible
import WebKit

public extension LarkUIKitExtension where BaseType: WKWebView {
    func sendMessage(functionName: String, arguments: [Any], completionHandler: ((Any?, Error?) -> Void)? = nil) {
        if JSONSerialization.isValidJSONObject(arguments) {
            let script = "\(functionName).apply(null,\(JSONStringWithObject(object: arguments)))"
                .lu.transformToExecutableScript()

            self.base.evaluateJavaScript(
                script,
                completionHandler: completionHandler
            )
        } else {
            let errMsg = "arguments is not valid JSONObject!"
            if let completionHandler = completionHandler {
                let error = NSError(domain: "LarkUIKitExtension+Lark", code: 0, userInfo: ["errMsg": errMsg]) as Error
                completionHandler(nil, error)
            }
        }
    }
}
