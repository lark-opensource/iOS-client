//
//  OpenAPIChatIDToOpenChatIDModel.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/20.
//

import Foundation
import LarkOpenAPIModel
import ECOProbe

final class OpenAPIChatIDToOpenChatIDParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "chatIDArray")
    public var chatIDArray: [String]

    public convenience init(chatIDs: [String]) throws {
        try self.init(with: ["chatIDArray": chatIDs])
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_chatIDArray]
    }
}

final class OpenChatIDItem: Codable {
    public let chatName: String?
    public let chatI18nNames: [String: String]?
    public let chatAvatarUrls: [String]?
    public let openChatId: String
    /// 自定义解析的key
    private enum CodingKeys : String, CodingKey {
        case chatName = "chat_name"
        case chatI18nNames = "chat_i18n_names"
        case chatAvatarUrls = "chat_avatar_urls"
        case openChatId = "open_chat_id"
    }
}

final class OpenAPIChatIDToOpenChatIDResult: OpenAPIBaseResult {
    public let apiTrace: OPTrace
    public let chatIDToOpenChatIDs: [String: Any]
    public init(chatIDToOpenChatIDs: [String: Any], apiTrace: OPTrace) {
        self.chatIDToOpenChatIDs = chatIDToOpenChatIDs
        self.apiTrace = apiTrace
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return chatIDToOpenChatIDs
    }
    
    subscript(chatID: String) -> OpenChatIDItem? {
        get {
            self.apiTrace.info("query OpenChatIDItem start")
            guard let item = chatIDToOpenChatIDs[chatID] else {
                self.apiTrace.error("query OpenChatIDItem chatID not exist")
                return nil
            }
            guard let dic = item as? [String: Any], JSONSerialization.isValidJSONObject(item) else {
                self.apiTrace.error("query OpenChatIDItem item is not valid json object")
                return nil
            }
            do {
                let json = try JSONSerialization.data(withJSONObject: dic)
                let result = try JSONDecoder().decode(OpenChatIDItem.self, from: json)
                return result
            } catch {
                self.apiTrace.error("query OpenChatIDItem decode error \(error.localizedDescription)")
                return nil
            }
        }
    }
}
