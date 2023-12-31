//
//  Validator.swift
//  MailNetwork
//
//  Created by weidong fu on 28/11/2017.
//

import Foundation
import SwiftyJSON

struct Validator {
    static func verifyData(_ data: Any?) -> Error? {
        // data format error
        guard let json = data as? [String: Any],
            let code = json["code"] as? Int,
            let msg = json["msg"] as? String else {
                return MailNetworkError.invalidParams
        }
        // server error
        guard let errorCode = MailNetworkError.Code(rawValue: code) else {
            return NSError(domain: msg, code: code, userInfo: nil)
        }
        guard errorCode == .success else {
            return MailNetworkError(code: errorCode)
        }
        return nil
    }
}
