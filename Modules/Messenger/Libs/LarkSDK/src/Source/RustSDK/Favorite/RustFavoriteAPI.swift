//
//  RustFavoriteAPI.swift
//  Lark
//
//  Created by lichen on 2018/6/15.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import LarkContainer
import LarkAccountInterface

final class RustFavoriteAPI: LarkAPI, FavoritesAPI {

    private let userPushCenter: PushNotificationCenter
    private let currentChatterId: String

    init(userPushCenter: PushNotificationCenter,
         currentChatterId: String,
         client: SDKRustService,
         onScheduler: ImmediateSchedulerType? = nil) {
        self.userPushCenter = userPushCenter
        self.currentChatterId = currentChatterId
        super.init(client: client, onScheduler: onScheduler)
    }

    func createFavorites(targets: [RustPB.Favorite_V1_CreateFavoritesRequest.FavoritesTarget]) -> Observable<Void> {
        var request = RustPB.Favorite_V1_CreateFavoritesRequest()
        request.favs = targets
        return self.client.sendAsyncRequest(request) { (_: CreateFavoritesResponse) -> Void in
            return Void()
        }.subscribeOn(scheduler)
    }

    /// originMergeForwardId: 私有话题群转发的详情页传入 其他业务传入nil
    /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题，需要originMergeForwardId
    func mergeFavorites(chatId: String, originMergeForwardId: String?, messageIds: [String]) -> Observable<Void> {
        var request = RustPB.Favorite_V1_MergeFavoriteRequest()
        request.chatID = chatId
        request.messageIds = messageIds
        if let originMergeForwardId = originMergeForwardId {
            request.originMergeForwardID = originMergeForwardId
        }
        return self.client.sendAsyncRequest(request) { (_: MergeFavoriteResponse) -> Void in
            return Void()
        }.subscribeOn(scheduler)
    }

    func deleteFavorites(ids: [String]) -> Observable<Void> {
        var request = RustPB.Favorite_V1_DeleteFavoriteRequest()
        request.ids = ids
        return self.client.sendAsyncRequest(request, transform: { (_: DeleteFavoriteResponse) -> Void in
            return Void()
        })
        .do(onNext: { [weak self] (_) in
            self?.userPushCenter.post(PushDeleteFavorites(favoriteIds: ids))
        })
        .subscribeOn(scheduler)
    }

    func getFavorites(time: Int, count: Int) -> Observable<GetFavoritesResult> {
        var request = RustPB.Favorite_V1_GetFavoritesRequest()
        request.time = Int64(time)
        request.count = Int32(count)
        return self.client.sendAsyncRequest(request, transform: { (response: GetFavoritesResponse) -> GetFavoritesResult in
            let ids = response.favoritesIds
            let entity = response.entity
            let favorites = ids.compactMap({ (id) -> RustPB.Basic_V1_FavoritesObject? in
                return entity.favorites[id]
            })
            let chats = RustAggregatorTransformer.transformToChatsMap(fromEntity: entity)
            let messages = RustAggregatorTransformer.transformToMessageModel(fromEntity: entity, currentChatterId: self.currentChatterId)
            return GetFavoritesResult(
                favorites: favorites,
                messages: messages,
                chats: chats,
                hasMore: response.hasMore_p)
        }).subscribeOn(scheduler)
    }

    func getFavoritesByIds(_ favoriteIds: [String]) -> Observable<GetFavoritesResult> {
        var request = RustPB.Favorite_V1_GetFavoriteInfoRequest()
        request.favoriteIds = favoriteIds
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Favorite_V1_GetFavoriteInfoResponse) -> GetFavoritesResult in
            let entity = response.entity
            let favorites = favoriteIds.compactMap({ (id) -> RustPB.Basic_V1_FavoritesObject? in
                return entity.favorites[id]
            })
            let chats = RustAggregatorTransformer.transformToChatsMap(fromEntity: entity)
            let messages = RustAggregatorTransformer.transformToMessageModel(fromEntity: entity, currentChatterId: self.currentChatterId)
            return GetFavoritesResult(
                favorites: favorites,
                messages: messages,
                chats: chats,
                hasMore: false)
        }).subscribeOn(scheduler)
    }
}
