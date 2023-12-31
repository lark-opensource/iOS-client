//
//  WPNetworkErrorInfo.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/29.
//

import Foundation
import ECOInfra

enum WPNetworkErrorType: Int {
    /// ECONetworkError包含了unknown类型，理论上不应该有unknown类型
    case unknown = 0
    case interceptorError = 1
    case validateFail = 2
    case innerError = 3
    case networkError = 4
    case requestError = 5
    case responseError = 6
    case serializeRequestFail = 7
    case serializeResponseFail = 8
    case httpError = 9
    case cancel = 10
}

struct WPNetworkErrorInfo {
    let errorType: WPNetworkErrorType
    var rustStatus: Int?
    var httpCode: Int?
    let errorCode: Int
    let errorUserInfo: [String: Any]
    let error: Error
    let domain: String
    let errorMessage: String

    init(error: ECONetworkError) {
        var nsError = error as NSError
        var userInfo: [String: Any] = [:]
        var msg: String?
        var httpCode: Int?
        var errorType: WPNetworkErrorType = .unknown

        switch error {
        case .http(let httpError):
            nsError = httpError as NSError
            httpCode = httpError.code
            msg = httpError.msg
            errorType = .httpError
            break
        case .middewareError(let middlewareError):
            nsError = middlewareError as NSError
            errorType = .interceptorError
            break
        case .validateFail(let validateError):
            nsError = validateError as NSError
            errorType = .validateFail
            break
        case .innerError(let innerError):
            nsError = (innerError.originError ?? innerError) as NSError
            errorType = .innerError
            break
        case .networkError(let networkError):
            nsError = networkError as NSError
            errorType = .networkError
            break
        case .requestError(let requestError):
            nsError = requestError as NSError
            errorType = .requestError
            break
        case .responseError(let responseError):
            nsError = responseError as NSError
            errorType = .responseError
            break
        case .serilizeRequestFail(let serializeError):
            nsError = serializeError as NSError
            errorType = .serializeRequestFail
            break
        case .serilizeResponseFail(let serializeError):
            nsError = serializeError as NSError
            errorType = .serializeResponseFail
            break
        case .unknown(let unknownError):
            nsError = unknownError as NSError
            errorType = .unknown
            break
        case .cancel:
            errorType = .cancel
            break
        @unknown default:
            errorType = .unknown
            break
        }

        var errorCode = nsError.code
        if let larkErrorCode = nsError.userInfo["larkErrorCode"] as? Int {
            errorCode = larkErrorCode
        }
        if let rustStatus = nsError.userInfo["larkErrorStatus"] as? Int {
            userInfo["rustStatus"] = "\(rustStatus)"
            self.rustStatus = rustStatus
        }
        if let httpStatusCode = httpCode {
            userInfo["httpCode"] = httpStatusCode
            self.httpCode = httpCode
        }
        let errorMessage = msg ?? nsError.localizedDescription
        userInfo[NSLocalizedDescriptionKey] = errorMessage

        self.errorType = errorType
        self.error = nsError
        self.errorUserInfo = userInfo
        self.errorCode = errorCode
        self.domain = nsError.domain
        self.errorMessage = errorMessage
    }
}
