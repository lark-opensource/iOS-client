//
//  IDPResponse.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/1/15.
//

import Foundation

class IDPResponse: ResponseV3 {
    var code: Int32
    var data: [String: Any] = [:]
    var errorInfo: V3LoginErrorInfo?

    required convenience init(dict: NSDictionary) throws {
        let serverCode = dict[V3.Const.code] as? Int32
        guard let code = serverCode else {
            throw DecodingError.valueNotFound(IDPResponse.self, DecodingError.Context(codingPath: [], debugDescription: V3.Const.code))
        }
        // 服务端返回错误
        if code != V3.Const.successCode {
            self.init(code: code, errorData: dict as? [String: Any])
        } else {
            // 请求服务端返回成功
            guard let data = dict[V3.Const.data] as? [String: Any] else {
                throw DecodingError.valueNotFound(IDPResponse.self, DecodingError.Context(codingPath: [], debugDescription: "\(V3.Const.data)"))
            }
            self.init(code: code, errorData: nil, data: data)
        }
    }

    init(code: Int32, errorData: [String: Any]?, data: [String: Any] = [:]) {
        self.code = code
        self.data = data
        if let error = errorData {
            self.errorInfo = V3LoginErrorInfo(dic: error)
        }
    }
}
