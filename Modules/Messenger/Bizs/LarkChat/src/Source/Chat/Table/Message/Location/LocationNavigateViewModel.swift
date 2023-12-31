//
//  LocationNavigateViewModel.swift
//  LarkChat
//
//  Created by Fangzhou Liu on 2019/6/14.
//  Copyright © 2019 ByteDance Inc. All rights reserved.
//

import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import RustPB

final class LocationNavigateViewModel {
    public let message: Message
    private let favoriteAPI: FavoritesAPI
    public let content: LocationContent
    public let isCrypto: Bool
    public let source: LocationSource

    init(message: Message, content: LocationContent,
         isCrypto: Bool,
         source: LocationSource,
         favoriteAPI: FavoritesAPI) {
        self.message = message
        self.content = content
        self.favoriteAPI = favoriteAPI
        self.isCrypto = isCrypto
        self.source = source
    }

    func createForwardBody() -> ForwardMessageBody {
        let body = ForwardMessageBody(message: self.message, type: .message(self.message.id), from: .location)
        return body
    }

    func createObservableFavorites() -> Observable<Void> {
        let favoritesTarget = createFavoritesTarget(id: self.message.id, type: .favoritesMessage, chatID: self.message.channel.id)
        return self.favoriteAPI.createFavorites(targets: [favoritesTarget])
    }

    func deleteObservableFavorites() -> Observable<Void> {
        if case .favorite(let id) = self.source {
            return self.favoriteAPI.deleteFavorites(ids: [id])
        }
        return .empty()
    }

    private func createFavoritesTarget(id: String, type: RustPB.Basic_V1_FavoritesType, chatID: String) -> RustPB.Favorite_V1_CreateFavoritesRequest.FavoritesTarget {
        var favoritesTarget = RustPB.Favorite_V1_CreateFavoritesRequest.FavoritesTarget()
        favoritesTarget.id = id
        favoritesTarget.type = type
        favoritesTarget.chatID = Int64(chatID) ?? 0
        return favoritesTarget
    }
}
