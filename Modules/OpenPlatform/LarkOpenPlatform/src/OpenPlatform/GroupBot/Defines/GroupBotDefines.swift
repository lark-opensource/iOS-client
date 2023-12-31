//
//  GroupBotDefines.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/4/15.
//

struct GroupBotDefines {
    //monitor
    static public let keyRequestID = "request_id"
    static public let keyChatID = "chat_id"
    static public let keyBotID = "bot_id"
    static public let keyQuery = "query"
    static public let keyScene = "scene"
    static public let keyEvent = "op_group_bot"
    
    //log
    static public let groupBotLogCategory = "GroupBot"
}

public enum AppGroupBotSource {
    case profile
    case searchPanel
}


