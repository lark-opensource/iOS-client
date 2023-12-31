//
//  Response.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation

public protocol MeegoResponseType {
    static func build(from data: Data) -> Result<Self, APIError>
}

public extension MeegoResponseType where Self: Codable {
    public static func build(from data: Data) -> Result<Self, APIError> {
        do {
            let response = try JSONDecoder().decode(Self.self, from: data)
            return .success(response)
        } catch {
            var apiError = APIError(httpStatusCode: MeegoNetClientErrorCode.jsonTransformToModelFailed)
            apiError.errorMsg = "jsonTransformToModelFailed"
            return .failure(apiError)
        }
    }
}

/// Mark - Response
public struct Response<T: Codable>: Codable, MeegoResponseType {
    public let code: Int    // bizErrorCode in http response
    public let msg: String  // localized message for error response
    public let data: T?     // http body data
    // codable key占位使用，默认为nil，不对外。
    private let error: LarkErrorInfo? = nil

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Response<T>.CodingKeys> = try decoder.container(keyedBy: Response<T>.CodingKeys.self)
        self.data = try? container.decodeIfPresent(T.self, forKey: Response<T>.CodingKeys.data)

        if let larkError = try? container.decodeIfPresent(LarkErrorInfo.self, forKey: Response<T>.CodingKeys.error) {
            // try to decode error with struct of lark error from lark gateway
            self.code = try container.decodeIfPresent(Int.self, forKey: Response<T>.CodingKeys.code) ?? -1
            self.msg = larkError.localizedMessage.message
        } else if let meegoError = try? container.decodeIfPresent(MeegoErrorInfo.self, forKey: Response<T>.CodingKeys.error) {
            // try to decode error with struct of meego error from meego gateway
            self.code = meegoError.code
            self.msg = meegoError.displayMsg.content
        } else {
            self.code = try container.decodeIfPresent(Int.self, forKey: Response<T>.CodingKeys.code) ?? -1
            self.msg = ""
        }
    }
}

///// Mark - LarkErrorInfo
public struct LarkErrorInfo: Codable {
    public let id: Int
    public let localizedMessage: LocalizedMessage
}

public struct LocalizedMessage: Codable {
    public let locale: String
    public let message: String
}

/// Mark - MeegoErrorInfo
public struct MeegoErrorInfo: Codable {
    public let code: Int
    public let msg: String

    public let displayMsg: ErrorDisplayMsg

    private enum CodingKeys: String, CodingKey {
        case code = "code"
        case msg = "msg"
        case displayMsg = "display_msg"
    }
}

public struct ErrorDisplayMsg: Codable {
    public let title: String
    public let content: String
}

/// Mark - EmptyDataResponse
public struct EmptyDataResponse: Codable {
}

public struct APIError: Error {
    public let host: String
    public let path: String
    public let httpStatusCode: Int
    public var logId: String

    public var errorMsg: String?
    public var ttnetErrorNum: Int?

    public init(host: String, path: String, httpStatusCode: Int, logId: String) {
        self.host = host
        self.path = path
        self.httpStatusCode = httpStatusCode
        self.logId = logId
    }

    public init(httpStatusCode: Int) {
        self.init(host: "", path: "", httpStatusCode: httpStatusCode, logId: "")
    }
}
