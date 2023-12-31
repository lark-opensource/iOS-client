//
//  UpdateInlineEntryHandler.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2021/8/7.
//

import Foundation
import LarkCore
import LarkContainer
import TangramService

// 个人签名Inline Push更新
final class UpdateInlineEntryHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return UpdateInlineEntryHandler(needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class UpdateInlineEntryHandler: PushHandler {
    let inlineService: MessageTextToInlineService?

    override init(needCachePush: Bool, userResolver: UserResolver) {
        inlineService = try? userResolver.resolve(assert: MessageTextToInlineService.self)
        super.init(needCachePush: needCachePush, userResolver: userResolver)
    }

    override func startObserve() throws {
        inlineService?.subscribePush { [weak self] (inlines: [String: InlinePreviewEntries]) in
            self?.dataSourceAPI?.update(original: { data in
                let message = data.message
                if let chatterID = message.fromChatter?.id,
                   let inline = inlines[chatterID],
                   let description = message.fromChatter?.description_p.text,
                   inline.textMD5 == description.md5() { // md5相同时才更新，否则可能仍然使用的是旧签名
                    return data
                }
                return nil
            })
        }
    }
}
