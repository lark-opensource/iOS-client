//
//  SendCardAditionalTextInfo.swift
//  LarkOpenPlatformInterface
//
//  Created by bytedance on 2022/9/15.
//

import Foundation

@objcMembers
public final class EMASendCardAditionalTextInfo: NSObject {
    public var status: Int?
    public var chatId: String?
    public var openChatId: String?
    public var message: String?
    
    public func toJsonObject() -> [AnyHashable: Any] {
        return ["status": status,
                "openChatId": openChatId ?? "",
                "additionalMessage": message ?? ""]
    }
}
