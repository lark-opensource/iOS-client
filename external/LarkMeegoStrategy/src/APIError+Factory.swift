//
//  APIError+Factory.swift
//  LarkMeegoStrategy
//
//  Created by shizhengyu on 2023/4/13.
//

import Foundation
import LarkMeegoNetClient

enum APIErrorFactory {
    static let urlParseError = {
        var error = APIError(httpStatusCode: MeegoNetClientErrorCode.unknownError)
        error.errorMsg = "pre request url parse failed"
        return error
    }()

    static let responseNotExpectedError = {
        var error = APIError(httpStatusCode: MeegoNetClientErrorCode.invalidResponseData)
        error.errorMsg = "response data is not expected"
        return error
    }()
}
