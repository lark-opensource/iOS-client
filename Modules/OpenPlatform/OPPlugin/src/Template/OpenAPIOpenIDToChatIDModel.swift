//
//  OpenAPIOpenIDToChatIDModel.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/2/2.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIOpenIDToChatIDParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "openID")
    public var openID: String

    public convenience init(openID: String) throws {
        let dict = ["openID": openID]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_openID]
    }

}

final class OpenAPIOpenIDToChatIDResult: OpenAPIBaseResult {

    public let chatID: String
    public init(chatID: String) {
        self.chatID = chatID
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["chatID": chatID]
    }
}
