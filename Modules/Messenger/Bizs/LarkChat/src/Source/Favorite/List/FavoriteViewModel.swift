//
//  FavoriteViewModel.swift
//  Lark
//
//  Created by lichen on 2018/6/4.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import LarkContainer
import LKCommonsLogging
import LarkCore
import RxRelay
import AppReciableSDK
import LarkSDKInterface
import TangramService
import RustPB
import LarkAccountInterface
import LarkMessengerInterface
import LarkUIKit

public final class FavoriteViewModel: UserResolverWrapper {
    public let userResolver: UserResolver

    static let logger = Logger.log(FavoriteViewModel.self, category: "favorite.list.view.model")

    public enum State {
        case `default`
        case loading
        case noMore
    }

    public let disposeBag: DisposeBag = DisposeBag()
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    public var viewModelFactory: FavoriteListViewModelFactory

    public var dataProvider: FavoriteDataProvider

    func appendFavorites(_ favorites: [RustPB.Basic_V1_FavoritesObject], messages: [String: Message], chats: [String: Chat]) {
        var temp = self.datasource.value
        temp += favorites.map({ (favorite) -> FavoriteCellViewModel in
            return viewModelFactory.create(favorite: favorite, messages: messages, chats: chats, dataProvider: dataProvider)
        })
        self.datasource.accept(temp)
    }

    public var datasource = BehaviorRelay<[FavoriteCellViewModel]>(value: [])

    public var state: State = .default
    private var enterCostInfo: EnterFavoriteCostInfo?

    private lazy var dataQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "ChatMessagesViewModelDataQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        return queue
    }()

    fileprivate lazy var dataScheduler: OperationQueueScheduler = {
        let scheduler = OperationQueueScheduler(operationQueue: dataQueue)
        return scheduler
    }()

    public init(userResolver: UserResolver, viewModelFactory: FavoriteListViewModelFactory, dataProvider: FavoriteDataProvider, enterCostInfo: EnterFavoriteCostInfo) {
        self.userResolver = userResolver
        self.viewModelFactory = viewModelFactory
        self.dataProvider = dataProvider
        self.enterCostInfo = enterCostInfo
        self.dataProvider.deleteFavoritesPush
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (ids) in
                guard let `self` = self else { return }
                self.datasource.accept(self.datasource.value.filter({ (viewModel) -> Bool in
                    return !ids.contains(viewModel.favorite.id)
                }))
            })
            .disposed(by: self.disposeBag)

        self.dataProvider.inlinePreviewVM.subscribePush { [weak self] push in
            self?.dataQueue.addOperation { [weak self] in
                guard let self = self else { return }
                let pair = push.inlinePreviewEntityPair
                let value = self.datasource.value
                value.forEach { vm in
                    let messageVM = vm as? FavoriteMessageViewModel
                    if let message = messageVM?.message,
                       let body = self.dataProvider.inlinePreviewVM.getInlinePreviewBody(message: message, pair: pair),
                       self.dataProvider.inlinePreviewVM.update(message: message, body: body) {
                        messageVM?.message = message // 触发message刷新
                    }
                }
                self.datasource.accept(self.datasource.value)
                // 来自SDK的push才需要判断是否重新拉取
                // 收藏的消息不懒加载，直接由SDK拉取
//                if push.type == .sdk {
//                    self.dataProvider.urlPreviewService.fetchNeedReloadURLPreviews(messages: updatedMessages)
//                }
            }
        }
    }

    @discardableResult
    func loadMore() -> Bool {
        if self.state != .default {
            return false
        }
        self.state = .loading

        var lastTime = 0
        if let last = self.datasource.value.last {
            lastTime = Int(last.favorite.createTime)
        }
        let start = CACurrentMediaTime()
        self.dataProvider.favoriteAPI.getFavorites(time: lastTime, count: 20)
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else { return }
                self.enterCostInfo?.sdkCost = Int((CACurrentMediaTime() - start) * 1000)
                self.appendFavorites(result.favorites, messages: result.messages, chats: result.chats)
                if result.hasMore {
                    self.state = .default
                } else {
                    self.state = .noMore
                }
                FavoriteViewModel.logger.debug("get favorites success")
                if let enterCostInfo = self.enterCostInfo {
                    enterCostInfo.end = CACurrentMediaTime()
                    AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                                          scene: .Favorite,
                                                                          event: .enterFavorite,
                                                                          cost: enterCostInfo.cost,
                                                                          page: FavoriteListController.pageName,
                                                                          extra: Extra(isNeedNet: true,
                                                                                       latencyDetail: enterCostInfo.reciableLatencyDetail,
                                                                                       metric: [:],
                                                                                       category: [:])))
                    self.enterCostInfo = nil
                }
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                if self.enterCostInfo != nil {
                    let apiError = error.underlyingError as? APIError
                    AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                    scene: .Pin,
                                                                    event: .enterFavorite,
                                                                    errorType: .SDK,
                                                                    errorLevel: .Fatal,
                                                                    errorCode: Int(apiError?.code ?? -1),
                                                                    userAction: nil,
                                                                    page: FavoriteListController.pageName,
                                                                    errorMessage: nil,
                                                                    extra: Extra(isNeedNet: true,
                                                                                 latencyDetail: [:],
                                                                                 metric: [:],
                                                                                 category: [:])))
                    self.enterCostInfo = nil
                }
                self.state = .default
                FavoriteViewModel.logger.error("get favorites failed", error: error)
            }).disposed(by: self.disposeBag)

        return true
    }
}

extension FavoriteViewModel: HasAssets {
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
