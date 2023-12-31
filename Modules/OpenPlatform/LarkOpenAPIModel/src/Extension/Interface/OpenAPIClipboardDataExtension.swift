//
//  OpenAPIClipboardDataExtension.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/8/9.
//

import UIKit

open class OpenAPIClipboardDataExtension: OpenBaseExtension {
    open func preCheck() -> OpenAPIError? {
        // 默认只判断App的前后台状态
        guard UIApplication.shared.applicationState == .active else {
            return  OpenAPIError(code: OpenAPISetClipboardDataErrorCode.inovkeInBackground)
                .setErrno(OpenAPIClipboardErrno.invokeInBackground)
        }
        return nil
    }
    
    open var alertWhiteListKey: String {
        ""
    }
}
