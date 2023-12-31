//
//  Errors.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/13.
//

import Foundation
import SwiftyJSON

public enum LSCError: Error {
    case domainInvalid
    case unsupportHTTPMethod
    case dataIsNil
    case responseIsNil
    case httpStatusError(_ code: Int, bodyJson: JSON?)
    case selfIsNil
}

extension LSCError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .domainInvalid:
            return "domain is valid."
        case .unsupportHTTPMethod:
            return "unsupport http method"
        case .dataIsNil:
            return "data is nil"
        case .responseIsNil:
            return "response is nil"
        case .httpStatusError(let code, let bodyJson):
            return "error for http code:\(code), msg: \(bodyJson?.debugDescription ?? "")"
        case .selfIsNil:
            return "self is nil"
        }
    }
}
