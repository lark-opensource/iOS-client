//
//  FavoriteDetailViewModel.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/14.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import RxSwift
import LarkCore
import LarkModel
import RxRelay
import LarkAccountInterface
import LarkContainer
import LarkMessengerInterface
import LarkUIKit

public final class FavoriteDetailViewModel: UserResolverWrapper {
    public var userResolver: UserResolver { dataProvider.userResolver }

    public var datasource = BehaviorRelay<[FavoriteCellViewModel]>(value: [])

    public let dataProvider: FavoriteDataProvider
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    public init(cellViewModel: FavoriteCellViewModel, dataProvider: FavoriteDataProvider) {
        self.datasource.accept([cellViewModel])
        self.dataProvider = dataProvider
    }

    public func deleteFavorite() -> Observable<Void> {
        let ids = self.datasource.value.map { $0.favorite.id }
        ChatTracker.trackFavouriteDelete()
        return self.dataProvider.favoriteAPI
            .deleteFavorites(ids: ids)
    }

    public func supportDelete() -> Bool {
        return true
    }

    public func supportForward() -> Bool {
        if let viewModel = self.datasource.value.first {
            return viewModel.supportForward()
        }
        return true
    }
}

extension FavoriteDetailViewModel: HasAssets {
    public func isMeSend(_ id: String) -> Bool {
        return id == userResolver.userID
    }

    public var messages: [Message] {
        return self.datasource.value.compactMap({ (vm) -> Message? in
            return (vm.content as? MessageFavoriteContent)?.message
        })
    }

    public func checkPreviewPermission(message: Message) -> PermissionDisplayState {
        return self.chatSecurityControlService?.checkPreviewAndReceiveAuthority(chat: nil, message: message) ?? .allow
    }
}
