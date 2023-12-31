//
//  WPResponse.swift
//  LarkWorkplaceModel
//
//  Created by Meng on 2022/11/6.
//

import Foundation

public struct WPResponse<ResponseData: Codable>: Codable {
    enum CodingKeys: String, CodingKey {
        case code
        case message = "msg"
        case data
    }

    /// server biz code
    public let code: Int

    /// server biz message
    public let message: String?

    /// biz data
    public let data: ResponseData?

    public init(code: Int, message: String, data: ResponseData?) {
        self.code = code
        self.message = message
        self.data = data
    }
}
