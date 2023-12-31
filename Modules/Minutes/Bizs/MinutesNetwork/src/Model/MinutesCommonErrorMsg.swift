//
//  MinutesCommonErrorMsg.swift
//  MinutesFoundation
//
//  Created by sihuahao on 2021/10/9.
//

import Foundation

public enum CommonErrorType: Int, Codable, ModelEnum {
    public static var fallbackValue: CommonErrorType = .unknown

    case unknown = 0
    case alert = 1
    case toastNormal = 2
    case toastSuccess = 3
    case toastFailed = 4
    case toastInfo = 5

}

public struct MinutesCommonErrorMsg: Codable, Error {
    public let type: CommonErrorType?
    public let content: CommonErrorContent?
    public let isShow: Bool?

    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case content = "content"
        case isShow = "isShow"
    }
}

public struct CommonErrorContent: Codable {
    public let title: String?
    public let body: String?

    private enum CodingKeys: String, CodingKey {
        case title = "title"
        case body = "body"
    }
}
