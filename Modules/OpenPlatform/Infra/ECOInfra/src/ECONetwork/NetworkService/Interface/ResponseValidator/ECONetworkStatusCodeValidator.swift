//
//  ECONetworkDefaultResponseValidator.swift
//  ECOInfra
//
//  Created by MJXin on 2021/10/22.
//

import Foundation
final class ECONetworkStatusCodeValidator<S: Sequence>: ECONetworkResponseValidator where S.Iterator.Element == Int {
    let acceptableStatusCodes: S
    
    // 初始化, 入参是 Sequence , 如 200...<300
    // 用于定义允许的 httpcode 范围
    init(statusCode acceptableStatusCodes: S) {
        self.acceptableStatusCodes = acceptableStatusCodes
    }
    
    // 校验 response 是否符合业务预期, 若不符合, 抛出错误
    public func validate(context: ECONetworkServiceContext, response: ECONetworkResponseOrigin) throws {
        let statusCode = response.response.statusCode
        if !acceptableStatusCodes.contains(statusCode) {
            var responseMessage: String?
            if let responseData = response.bodyData {
                responseMessage = String(
                    data: responseData,
                    encoding: .utf8
                )
            }
            let errorMessage = responseMessage ?? 
            HttpCode.message(statusCode: statusCode)
            let error = HttpError(code: statusCode, msg: errorMessage)
            throw ECONetworkError.http(error)
        }
    }
}
