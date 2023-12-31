//
//  Validator.swift
//  DocsNetwork
//
//  Created by weidong fu on 28/11/2017.
//

import Foundation
import SwiftyJSON

struct Validator {
    static func verifyData(_ data: Any?) -> Error? {
        // data format error
        let json = data as? [String: Any]
        let code = json?["code"] as? Int
        let msg = (json?["msg"] as? String) ?? (json?["message"] as? String)
        guard let code = code, let msg = msg else {
            DocsLogger.info("invalid params, code=\(String(describing: code)), msg=\(String(describing: msg))")
                return DocsNetworkError.invalidParams
        }
        // server error
        guard let errorCode = DocsNetworkError.Code(rawValue: code) else {
            return NSError(domain: msg, code: code, userInfo: nil)
        }
        if var docsErr = DocsNetworkError(errorCode.rawValue) {
            docsErr.set(msg: msg)
            return docsErr
        }
        return nil
    }
}
