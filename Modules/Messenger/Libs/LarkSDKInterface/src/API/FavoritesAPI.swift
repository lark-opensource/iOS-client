//
//  FavoritesAPI.swift
//  LarkSDKInterface
//
//  Created by lichen on 2018/6/14.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public struct GetFavoritesResult {
    public let favorites: [RustPB.Basic_V1_FavoritesObject]
    public let messages: [String: Message]
    public let chats: [String: Chat]
    public let hasMore: Bool

    public init(favorites: [RustPB.Basic_V1_FavoritesObject],
                messages: [String: Message],
                chats: [String: Chat],
                hasMore: Bool) {
        self.favorites = favorites
        self.messages = messages
        self.chats = chats
        self.hasMore = hasMore
    }
}

public protocol FavoritesAPI {

    func createFavorites(targets: [RustPB.Favorite_V1_CreateFavoritesRequest.FavoritesTarget]) -> Observable<Void>
    /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题
    /// 服务端需要这个原始originMergeForwardId，来支持转发, 私有话题群转发的详情页传入  其他业务传入nil
    func mergeFavorites(chatId: String, originMergeForwardId: String?, messageIds: [String]) -> Observable<Void>

    func deleteFavorites(ids: [String]) -> Observable<Void>

    func getFavorites(time: Int, count: Int) -> Observable<GetFavoritesResult>

    func getFavoritesByIds(_ favoriteIds: [String]) -> Observable<GetFavoritesResult>
}

public typealias FavoritesAPIAPIProvider = () -> FavoritesAPI
