//
//  GetChatIdAPI.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2019/9/17.
//

import Foundation
import LarkContainer

extension OpenPlatformAPI {
    public static func GetChatIdAPI(openId: String, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getChatIdByOpenId, resolver: resolver)
            .appendParam(key: .open_id, value: openId)
            .useEncrypt()
            .useSession()
    }

    public static func GetChatIdAPI(openChatId: String, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getChatIdByOpenChatId, resolver: resolver)
            .appendParam(key: .open_chat_id, value: openChatId)
            .useEncrypt()
            .useSession()
    }
}

final class GetChatIdAPIResponse: APIResponse {
    public lazy var chatId: String? = {
        return self.data?["chatid"].string
    }()

    public func chatIdWithOpenChatId(openChatId: String) -> String? {
        return self.data?[openChatId].rawString()
    }
}
