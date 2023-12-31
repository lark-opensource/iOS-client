//
//  Favorite.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/5.
//

import Foundation
import LarkModel
import UniverseDesignToast
import RxSwift
import LarkMessageBase
import LarkSDKInterface
import LarkContainer
import RustPB
import LarkCore
import LarkOpenChat

public final class FavoriteMessageActionSubModule: MessageActionSubModule {
    private let disposeBag = DisposeBag()
    private weak var targetVC: UIViewController?
    @ScopedInjectedLazy private var favoritesAPI: FavoritesAPI?

    public override var type: MessageActionType {
        return .favorite
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        switch model.message.type {
        case .text, .post, .audio, .image, .media, .location, .sticker:
            return true
        case .file:
            // 局域网文件不支持收藏
            if let fileContent = model.message.content as? FileContent {
                return fileContent.fileSource != .lanTrans
            }
            return true
        case .folder:
            // 局域网文件夹不支持收藏
            if let folderContent = model.message.content as? FolderContent {
                return folderContent.fileSource != .lanTrans
            }
            return true
        case .card, .email, .hongbao, .vote,
             .commercializedHongbao, .system, .shareGroupChat,
             .shareUserCard, .shareCalendarEvent,
             .calendar, .generalCalendar, .videoChat, .todo, .unknown:
            return false
        case .mergeForward:
            if (model.message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false {
                return false
            }
            return true
        @unknown default:
            return false
        }
    }

    private func createFavoritesTarget(id: String, type: RustPB.Basic_V1_FavoritesType, chatID: String) -> RustPB.Favorite_V1_CreateFavoritesRequest.FavoritesTarget {
        var favoritesTarget = RustPB.Favorite_V1_CreateFavoritesRequest.FavoritesTarget()
        if let originMergeForwardId = (context as? PrivateThreadMessageActionContext)?.originMergeForwardId {
            favoritesTarget.originMergeForwardID = originMergeForwardId
        }
        favoritesTarget.id = id
        favoritesTarget.type = type
        favoritesTarget.chatID = Int64(chatID) ?? 0
        return favoritesTarget
    }

    private func handle(message: Message, chat: Chat) {
        guard let targetView = try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self).pageAPI?.view else { return }
        let favoritesTarget = createFavoritesTarget(
            id: message.id,
            type: .favoritesMessage,
            chatID: message.channel.id
        )
        UDToast.showLoading(
            with: BundleI18n.LarkMessageCore.Lark_Legacy_BaseUiLoading,
            on: targetView,
            disableUserInteraction: true
        )
        LarkMessageCoreTracker.trackAddFavourite(chat: chat, messageID: message.id, messageType: message.type)
        favoritesAPI?.createFavorites(targets: [favoritesTarget])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak targetView] _ in
                guard let targetView = targetView else { return }
                UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_ChatViewFavorites, on: targetView)
            }, onError: { [weak targetView] error in
                guard let targetView = targetView else { return }
                UDToast.showFailure(
                    with: BundleI18n.LarkMessageCore.Lark_Legacy_SaveFavoriteFail,
                    on: targetView,
                    error: error
                )
            }).disposed(by: disposeBag)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_AddToFavorite,
                                 icon: BundleResources.Menu.menu_favorite,
                                 trackExtraParams: ["click": "favorite",
                                                    "target": "none"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}
