//
//  FavoriteListViewModelFactory.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/13.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import LarkModel
import RustPB
import LarkFeatureGating

public final class FavoriteListViewModelFactory {

    public init() {}

    public func create(favorite: RustPB.Basic_V1_FavoritesObject, messages: [String: Message], chats: [String: Chat], dataProvider: FavoriteDataProvider) -> FavoriteCellViewModel {
        var viewModel: FavoriteCellViewModel?

        switch favorite.type {
        case .favoritesMessage, .favoritesMergeFavorite:
            viewModel = self.createMessageVM(favorite: favorite, messages: messages, chats: chats, dataProvider: dataProvider)
        case .favoritesUnknown:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
        return viewModel ?? self.unknownViewModel(favorite: favorite, dataProvider: dataProvider)
    }

    func createMessageVM(favorite: RustPB.Basic_V1_FavoritesObject, messages: [String: Message], chats: [String: Chat], dataProvider: FavoriteDataProvider) -> FavoriteCellViewModel? {
        guard let message = messages[favorite.content.messageID] else { return nil }
        let chat = chats[message.channel.id]
        let content = MessageFavoriteContent(type: favorite.type, chat: chat, message: message)
        switch message.type {
        case .text:
            return NewFavoritePostMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
        case .post:
            return NewFavoritePostMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
        case .image:
            return FavoriteImageMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
        case .media:
            return FavoriteVideoMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
        case .sticker:
            return FavoriteStickerMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
        case .file:
            return FavoriteFileMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
        case .folder:
            return FavoriteFolderMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
        case .audio:
            let audioVM = FavoriteAudioMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
            return audioVM
        case .location:
            return FavoriteLocationMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
        case .mergeForward:
            if let mergeForwardContent = message.content as? MergeForwardContent, mergeForwardContent.isFromPrivateTopic {
                return FavoriteMergeForwardPostCardMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
            } else {
                return FavoriteMergeForwardMessageViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
            }
        case .unknown, .system, .email, .shareGroupChat, .shareUserCard, .calendar, .generalCalendar, .card, .shareCalendarEvent, .hongbao, .commercializedHongbao, .videoChat, .todo, .diagnose, .vote:
            // TODO: todo 适配
            return nil
        @unknown default:
            assert(false, "new value")
            return nil
        }
    }

    public func unknownViewModel(favorite: RustPB.Basic_V1_FavoritesObject, dataProvider: FavoriteDataProvider) -> FavoriteCellViewModel {
        return FavoriteUnknownViewModel(userResolver: dataProvider.userResolver, favorite: favorite, content: UnknownFavoriteContent(), dataProvider: dataProvider)
    }
}
