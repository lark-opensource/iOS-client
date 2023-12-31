//
//  OpenAPIOpenChatIDToChatIDModel.swift
//  LarkOpenAPIModel
//
//  Created by lixiaorui on 2021/2/9.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIOpenChatIDToChatIDParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "openChatIDs")
    public var openChatIDs: [String]

    public convenience init(openChatIDs: [String]) throws {
        let dict = ["openChatIDs": openChatIDs]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_openChatIDs]
    }

}

final class OpenAPIOpenChatIDToChatIDResult: OpenAPIBaseResult {

    public let openChatIDToChatIDs: [String: String]
    public init(openChatIDToChatIDs: [String: String]) {
        self.openChatIDToChatIDs = openChatIDToChatIDs
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return openChatIDToChatIDs
    }
}
