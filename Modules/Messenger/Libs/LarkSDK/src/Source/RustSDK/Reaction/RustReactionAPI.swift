//
//  RustReactionAPI.swift
//  Lark
//
//  Created by linlin on 2017/11/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import ServerPB
import LarkSDKInterface
import LarkEmotionKeyboard

final class RustReactionAPI: LarkAPI, ReactionAPI, ReactionSkinTonesAPI {
    func sendReaction(messageId: String, reactionType: String) -> Observable<Void> {
        var request = CreateReactionRequest()
        request.messageID = messageId
        request.type = reactionType
        return self.client.sendAsyncRequest(request)
    }

    func deleteISendReaction(messageId: String, reactionType: String) -> Observable<Void> {
        var request = DeleteReactionRequest()
        request.messageID = messageId
        request.type = reactionType
        return self.client.sendAsyncRequest(request)
    }

    func updateRecentlyUsedReaction(reactionType: String) -> Observable<Void> {
        var request = ServerPB_Reactions_UpdateUserRecentlyUsedReactionRequest()
        request.reactionKey = reactionType
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .updateUserRecentlyUsedEmoji)
    }

    func getUserReactions() -> Observable<[String]> {
        var request = GetUserReactionsRequest()
        request.isFromLocal = true
        return self.client.sendAsyncRequest(request, transform: { (response: GetUserReactionsResponse) -> [String] in
            return response.userReactions.keys + response.userReactions.extraKeys
        })
    }

    func getUsedReactions() -> Observable<[String]> {
        var request = GetUsedReactionsRequest()
        request.isFromLocal = true
        return self.client.sendAsyncRequest(request, transform: { (response: GetUsedReactionsResponse) -> [String] in
            return response.keys
        })
    }

    func syncUserReactions() -> Observable<[String]> {
        var request = GetUserReactionsRequest()
        request.isFromLocal = false
        return self.client.sendAsyncRequest(request, transform: { (response: GetUserReactionsResponse) -> [String] in
            return response.userReactions.keys + response.userReactions.extraKeys
        })
    }

    func syncUsedReactions() -> Observable<[String]> {
        var request = GetUsedReactionsRequest()
        request.isFromLocal = false
        return self.client.sendAsyncRequest(request, transform: { (response: GetUsedReactionsResponse) -> [String] in
            return response.keys
        })
    }

    func updateReactionSkin(defaultReactionKey: String, skinKey: String) -> Observable<Void> {
        var request = UpdateUserReactionSkinRequest()
        request.reactionToSkinKey = [defaultReactionKey: skinKey]
        return self.client.sendAsyncRequest(request)
    }
}
