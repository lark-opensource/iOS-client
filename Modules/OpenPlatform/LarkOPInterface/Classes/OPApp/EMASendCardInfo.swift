//
//  SendCardInfo.swift
//  LarkOpenPlatformInterface
//
//  Created by bytedance on 2022/9/15.
//

import Foundation

@objcMembers
public final class EMASendCardInfo: NSObject {
    public var status: Int?
    public var openChatId: String?
    public var openMessageId: String?
    
    public func toJsonObject() -> [AnyHashable: Any] {
        return ["status": status,
                "openChatId": openChatId ?? "",
                "openMessageId": openMessageId ?? ""]
    }
}


