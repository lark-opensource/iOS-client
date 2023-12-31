//
//  SearchCellViewModel.swift
//  Lark
//
//  Created by ChalrieSu on 02/04/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkSceneManager
import RustPB
import LarkSearchCore
import LarkContainer
import LarkMessengerInterface

protocol SearchCellViewModel: SearchCellPresentable {
    var searchResult: SearchResultType { get }

    /// 埋点信息
    var searchClickInfo: String { get }

    var resultTypeInfo: String { get }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel?

    /// 返回支持 iPad 多 scene 场景的拖拽能力
    func supportDragScene() -> Scene?

    func supprtPadStyle() -> Bool
}

final class DemoSearchCellViewModel: SearchCellViewModel {
    var searchResult: SearchResultType
    /// 埋点信息
    var searchClickInfo: String = ""
    var resultTypeInfo: String = ""
    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? { return nil }
    /// 返回支持 iPad 多 scene 场景的拖拽能力
    func supportDragScene() -> Scene? { return nil}
    func supprtPadStyle() -> Bool { return false }
    init(searchResult: SearchResultType) {
        self.searchResult = searchResult
    }
}
struct SearchViewModelSection {
    let searchCallBack: SearchCallBack

    var searchScene: SearchSceneSection { searchCallBack.searchScene }
    var imprID: String? { searchCallBack.imprID }
    var searchViewModels: [SearchCellViewModel]

    init(searchCallBack: SearchCallBack, searchViewModels: [SearchCellViewModel]) {
        self.searchCallBack = searchCallBack
        self.searchViewModels = searchViewModels
    }
}

extension SearchViewModelSection: Equatable {
    static func == (lhs: SearchViewModelSection, rhs: SearchViewModelSection) -> Bool {
        // 通过相等复用，修复SearchDataCenter的增量Push导致重建ViewModel，打断点击的问题。
        // 但当发起新请求时，不应该复用（远端更新，高亮更新等）。此处用contextID来区分是否新请求。
        // 没实现在searchResult的== 是因为去重还是用id和type来保证唯一性的。避免影响到其它代码
        return lhs.searchScene == rhs.searchScene && lhs.searchCallBack.contextID == rhs.searchCallBack.contextID
          && lhs.searchCallBack.results.elementsEqual(rhs.searchCallBack.results) { $0.optionIdentifier == $1.optionIdentifier }
    }
}

extension UniversalRecommendResult {
    func peakFeedCard(_ feedAPI: FeedAPI, disposeBag: DisposeBag) {
        guard let feedCardId = self.feedId else { return }
        var entityType: RustPB.Basic_V1_FeedCard.EntityType
        switch type {
        case .groupChat, .user, .message, .cryptoP2PChat, .bot:
            entityType = .chat
        @unknown default:
            return
        }
        switch resultMeta.typedMeta {
        case .messageMeta(let messageMeta):
            if messageMeta.position == replyInThreadMessagePosition {
                entityType = .msgThread
            }
        @unknown default:
            break
        }
        feedAPI.peakFeedCard(by: feedCardId, entityType: entityType)
            .subscribe(onError: { (error) in
                UniversalRecommendService.logger.error("Peak feed card faild", additionalData: [
                    "feedCardId": feedCardId,
                    "entityType": "\(entityType)"], error: error)
            }).disposed(by: disposeBag)
    }

    var feedId: String? {
        if case .groupChat = type {
            return id
        }
        switch resultMeta.typedMeta {
        case .messageMeta(let messageMeta):
            if messageMeta.position == replyInThreadMessagePosition {
                return messageMeta.threadID
            }
            return messageMeta.chatID
        case .userMeta(let chatterMeta):
            return chatterMeta.p2PChatID
        case .cryptoP2PChatMeta(let cryptoP2PChatMeta):
            return cryptoP2PChatMeta.id
        @unknown default:
            return nil
        }
    }
}

extension SearchCellViewModel {
    func peakFeedCard(_ feedAPI: FeedAPI, disposeBag: DisposeBag) {
        guard let feedCardId = self.feedId else { return }
        var entityType: RustPB.Basic_V1_FeedCard.EntityType
        switch self.searchResult.type {
        case .chat, .chatter, .message, .cryptoP2PChat, .shieldP2PChat, .bot:
            entityType = .chat
        default:
            return
        }

        switch searchResult.meta {
        case .message(let messageMeta):
            if messageMeta.position == replyInThreadMessagePosition {
                entityType = .msgThread
            }
        default:
            break
        }

        // Bug fix，如果 feedCardId 为空，在拿到 feedCardId 后延后调用 peakFeedCard，需要注意的是以后都需要考虑 feedCardId 为空的情况，要在 SearchxxViewModel 中单独调用
        if !feedCardId.isEmpty {
            feedAPI.peakFeedCard(by: feedCardId, entityType: entityType)
                .subscribe(onError: { (error) in
                    SearchRootViewController.logger.error("Peak feed card faild", additionalData: [
                        "feedCardId": feedCardId,
                        "entityType": "\(entityType)"], error: error)
                }).disposed(by: disposeBag)
        }
    }

    func peakFeedCard(_ feedAPI: FeedAPI, feedCardId: String, disposeBag: DisposeBag) {
        var entityType: RustPB.Basic_V1_FeedCard.EntityType
        switch self.searchResult.type {
        case .chat, .chatter, .message, .cryptoP2PChat, .shieldP2PChat, .bot:
            entityType = .chat
        default:
            return
        }

        switch searchResult.meta {
        case .message(let messageMeta):
            if messageMeta.position == replyInThreadMessagePosition {
                entityType = .msgThread
            }
        default:
            break
        }

        // Bug fix，如果 feedCardId 为空，在拿到 feedCardId 后延后调用 peakFeedCard，需要注意的是以后都需要考虑 feedCardId 为空的情况，要在 SearchxxViewModel 中单独调用
        if !feedCardId.isEmpty {
            feedAPI.peakFeedCard(by: feedCardId, entityType: entityType)
                .subscribe(onError: { (error) in
                    SearchRootViewController.logger.error("Peak feed card faild", additionalData: [
                        "feedCardId": feedCardId,
                        "entityType": "\(entityType)"], error: error)
                }).disposed(by: disposeBag)
        }
    }

    var feedId: String? {
        if case .chat = searchResult.type {
            return searchResult.id
        }
        switch searchResult.meta {
        case .message(let messageMeta):
            if messageMeta.position == replyInThreadMessagePosition {
                return messageMeta.threadID
            }
            return messageMeta.chatID
        case .chatter(let chatterMeta):
            return chatterMeta.p2PChatID
        case .cryptoP2PChat(let cryptoP2PChatMeta):
            return cryptoP2PChatMeta.id
        case .shieldP2PChat(let shieldP2PChatMeta):
            return shieldP2PChatMeta.id
        default:
            return nil
        }
    }

    var avatarID: String {
        switch searchResult.meta {
        case .message(let message):
            // 大搜场景，搜索到的message源自单聊时始终展示对方头像，源自群聊时始终展示群头像
            return message.isP2PChat ? message.p2PChatterIDString : message.chatID
        default: return searchResult.avatarID ?? ""
        }
    }

    func supportDragScene() -> Scene? {
        return nil
    }

    func isPadFullScreenStatus(resolver: UserResolver) -> Bool {
        if let service = try? resolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
            return service.isNeedChangeCellLayout()
        }
        return false
    }
}

protocol UnreadState {
    var unreadCount: Observable<Int> { get }
}

extension UnreadState {
    static func unreadCount(for item: SearchResultType) -> Int {
        // 跟PC对齐
        switch item.meta {
        case .chat(let meta):
            return Int([
                meta.lastMessagePosition - meta.readPosition,
                meta.lastMessagePositionBadgeCount - meta.readPositionBadgeCount
            ].min() ?? 0)
        case .chatter(let meta as ChatterMeta), .cryptoP2PChat(let meta as ChatterMeta), .shieldP2PChat(let meta as ChatterMeta):
            return Int([
                meta.lastMessagePosition - meta.readPosition,
                meta.lastMessagePositionBadgeCount - meta.readPositionBadgeCount
            ].min() ?? 0)
        default: return 0
        }
    }
}
