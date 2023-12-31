//
//  ChattersPushHandler.swift
//  Lark-Rust
//
//  Created by liuwanlin on 2017/12/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

#if LarkAccount_CHATTER
import RustPB
import LarkRustClient
import LarkModel
import LarkContainer
import LKCommonsLogging
import LarkAccountInterface

class ChattersPushHandler: BaseRustPushHandler<RustPB.Basic_V1_Entity> {
    static var logger = Logger.log(ChattersPushHandler.self, category: "Rust.PushHandler")

    let pushCenter: PushNotificationCenter

    init(pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
    }

    override public func doProcessing(message: RustPB.Basic_V1_Entity) {
        var chatters = message.chatters.map { tuple -> LarkModel.Chatter in
            return LarkModel.Chatter.transform(pb: tuple.value)
        }
        let chatChatters = message.chatChatters.flatMap { (_, chatChatter) -> [LarkModel.Chatter] in
            return chatChatter.chatters.map({ (_, chatter) -> LarkModel.Chatter in
                return LarkModel.Chatter.transform(pb: chatter)
            })
        }
        chatters.append(contentsOf: chatChatters)
        self.pushCenter.post(AccountPushChatters(chatters: chatters))
    }
}
#endif
