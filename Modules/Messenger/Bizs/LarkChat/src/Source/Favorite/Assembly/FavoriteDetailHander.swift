//
//  FavoriteDetailHander.swift
//  LarkChat
//
//  Created by liluobin on 2023/7/5.
//

import UIKit
import Foundation
import LarkContainer
import LarkModel
import EENavigator
import LarkMessengerInterface
import LarkNavigator
import LarkCore
import LarkMessageCore
import LarkSDKInterface
import RxSwift
import LKCommonsLogging
import UniverseDesignToast

class FavoriteDetailHander: UserTypedRouterHandler {

    static let logger = Logger.log(FavoriteDetailHander.self, category: "FavoriteDetailHander")

    let disposeBag = DisposeBag()

    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    func handle(_ body: FavoriteDetailBody, req: EENavigator.Request, res: Response) throws {
        res.end(resource: EmptyResource())
        let favoriteAPI = try resolver.resolve(assert: FavoritesAPI.self)
        let favoriteId = body.favoriteId
        let vc = req.from.fromViewController
        Self.logger.info("app link jump to  FavoriteDetailBody id \(favoriteId) -- type \(body.favoriteType)")
        favoriteAPI.getFavoritesByIds([favoriteId])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak vc] result in
                guard let self = self, let vc = vc else { return }
                if let first = result.favorites.first, let dataProvider = try? FavoriteVMDataProvider(resolver: self.userResolver) {
                    let factory = FavoriteListViewModelFactory()
                    let vm = factory.create(favorite: first,
                                            messages: result.messages,
                                            chats: result.chats,
                                            dataProvider: dataProvider)
                    FavoriteDetailHander.pushDetailController(with: vm,
                                                              targetVC: vc,
                                                              navigator: self.navigator,
                                                              resolver: self.resolver,
                                                              userResolver: self.userResolver)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_FavoriteOpenLinkFail_Toast, on: vc.view)
                    Self.logger.error("getFavoritesById \(favoriteId) empty data")
                }
            }, onError: { [weak vc] (error) in
                if let view = vc?.view {
                    UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_FavoriteOpenLinkFail_Toast, on: view)
                }
                Self.logger.error("getFavoritesById \(favoriteId) ", error: error)
            }).disposed(by: self.disposeBag)

    }

    static func pushDetailController(with cellViewModel: FavoriteCellViewModel,
                                     targetVC: UIViewController,
                                     navigator: UserNavigator,
                                     resolver: Resolver,
                                     userResolver: UserResolver) {

        let message = (cellViewModel.content as? MessageFavoriteContent)?.message
        // 未知类型的收藏或消息时未知消息的，不显示vc
        if cellViewModel.favorite.type == .favoritesUnknown ||
            message?.type == .unknown ||
            ((message?.content as? UnknownContent) != nil) {
            return
        }

        // 合并转发收藏消息的页面单独处理
        if let cellVMContent = cellViewModel.content as? MessageFavoriteContent,
            let mergeForwardContent = cellVMContent.message.content as? LarkModel.MergeForwardContent {
            if mergeForwardContent.isFromPrivateTopic {
                pushToPostForwardDetailWith(cellVMContent.message,
                                            currentChatterId: userResolver.userID,
                                            chat: mergeForwardContent.fromThreadChat,
                                            targetVC: targetVC,
                                            navigator: navigator)
            } else {
                let body = FavoriteMergeForwardDetailBody(
                    message: cellVMContent.message,
                    chatId: cellVMContent.message.channel.id,
                    favoriteId: cellViewModel.favorite.id)
                navigator.push(body: body, from: targetVC)
            }
            Self.logger.info("FavoriteDetailHander push to MergeForwardContent -\(cellViewModel.favorite.id) - isFromPrivateTopic: \(mergeForwardContent.isFromPrivateTopic)")
            return
        }

        guard let dataProvider = try? FavoriteVMDataProvider(resolver: userResolver) else { return }
        let detailVM = FavoriteDetailViewModel(cellViewModel: cellViewModel, dataProvider: dataProvider)
        // 其他收藏消息
        let detailVCDispatcher = RequestDispatcher(userResolver: userResolver, label: String(describing: FavoriteDetailControler.self))
        let detailController = FavoriteDetailControler(viewModel: detailVM, dispatcher: detailVCDispatcher)
        FavoriteActionFactory(
            resolver: resolver,
            dispatcher: detailVCDispatcher,
            controller: detailController,
            assetsProvider: detailVM
        ).registerActions()
        detailController.cellFactory = FavoriteDetailCellFactory(
            dispatcher: detailVCDispatcher,
            tableView: detailController.table
        )
        navigator.push(detailController, from: targetVC)
        Self.logger.info("FavoriteDetailHander push to FavoriteDetail -\(cellViewModel.favorite.id)")
    }

    private static func pushToPostForwardDetailWith(_ message: Message, currentChatterId: String, chat: Chat?, targetVC: UIViewController, navigator: UserNavigator) {
        guard let content = message.content as? MergeForwardContent,
              let thread = content.thread else {
            return
        }
        /// 如果当前是群成员  需要跳转原来的详情页
        if ReplyInThreadMergeForwardDataManager.isChatMember(content: content, currentChatterId: currentChatterId) {
            if thread.isReplyInThread {
                let body = ReplyInThreadByIDBody(threadId: thread.id,
                                                 sourceType: .forward_card)
                navigator.push(body: body, from: targetVC)
            } else {
                let body = ThreadDetailByIDBody(threadId: thread.id)
                navigator.push(body: body, from: targetVC)
            }
        } else {
            let body = ThreadPostForwardDetailBody(originMergeForwardId: message.id, message: message, chat: content.fromThreadChat ?? ReplyInThreadMergeForwardDataManager.getFromChatFor(content: content))
            navigator.push(body: body, from: targetVC)
        }
    }
}
