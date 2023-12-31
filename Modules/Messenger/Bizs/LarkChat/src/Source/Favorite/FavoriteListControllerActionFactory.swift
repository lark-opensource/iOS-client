//
//  FavoriteListControllerActionFactory.swift
//  LarkFavorite
//
//  Created by lichen on 2018/6/25.
//

import UIKit
import Foundation
import LarkContainer
import LarkActionSheet
import LarkUIKit
import LarkCore
import RxSwift
import EENavigator
import LarkAlertController
import LarkMessengerInterface
import UniverseDesignToast

public final class FavoriteListControllerActionFactory {
    let dispatcher: RequestDispatcher
    let controller: FavoriteListController

    public init(dispatcher: RequestDispatcher,
         controller: FavoriteListController) {
        self.dispatcher = dispatcher
        self.controller = controller
    }

    public func registerActions() {
        dispatcher.register(FavoriteLongPressActionMessage.self, loader: { [unowned controller, weak dispatcher] in
            return FavoriteLongPressAction(targetVC: controller, dispatcher: dispatcher)
        }, cacheHandler: true)
    }
}

open class FavoriteLongPressActionMessage: LarkContainer.Request {
    public typealias Response = EmptyResponse

    public var viewModel: FavoriteCellViewModel
    public var triggerView: UIView
    public var triggerLocation: CGPoint

    public init(viewModel: FavoriteCellViewModel, triggerView: UIView, triggerLocation: CGPoint) {
        self.viewModel = viewModel
        self.triggerView = triggerView
        self.triggerLocation = triggerLocation
    }
}

public final class FavoriteLongPressAction: RequestHandler<FavoriteLongPressActionMessage> {
    unowned let targetVC: FavoriteListController
    weak var dispatcher: RequestDispatcher?
    fileprivate let disposeBag: DisposeBag = DisposeBag()

    public init(targetVC: FavoriteListController, dispatcher: RequestDispatcher?) {
        self.targetVC = targetVC
        self.dispatcher = dispatcher
    }

    override public func handle(_ message: FavoriteLongPressActionMessage) -> EmptyResponse? {

        let adapter = ActionSheetAdapter()
        let adapterSource = ActionSheetAdapterSource(
            sourceView: message.triggerView,
            sourceRect: CGRect(x: message.triggerLocation.x, y: message.triggerLocation.y, width: 0, height: 0),
            arrowDirection: .unknown
        )
        let actionSheet = adapter.create(level: .normal(source: adapterSource))

        let favoriteId = message.viewModel.favorite.id
        let viewModel = message.viewModel
        if viewModel.supportForward(), let message = (message.viewModel.content as? MessageFavoriteContent)?.message {
            adapter.addItem(title: BundleI18n.LarkChat.Lark_Legacy_Forward) { [weak self, weak viewModel] in
                guard let `self` = self, let viewModel else { return }
                ChatTracker.trackFavouriteForward()
                let body = ForwardMessageBody(message: message, type: .favorite(favoriteId), from: .favorite, supportToMsgThread: true)
                viewModel.navigator.present(
                    body: body,
                    from: self.targetVC,
                    prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
            }
        }

        if viewModel.supportDelete() {
            adapter.addItem(title: BundleI18n.LarkChat.Lark_Legacy_Remove) { [weak self, weak viewModel] in
                guard let self, let viewModel else { return }
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkChat.Lark_Legacy_SaveBoxDeleteConfirm)
                alertController.addCancelButton()
                alertController.addDestructiveButton(text: BundleI18n.LarkChat.Lark_Legacy_Remove, dismissCompletion: {
                    let hud = UDToast.showDefaultLoading(on: self.targetVC.view, disableUserInteraction: true)
                    ChatTracker.trackFavouriteDelete()
                    self.targetVC
                        .viewModel
                        .dataProvider
                        .favoriteAPI
                        .deleteFavorites(ids: [message.viewModel.favorite.id])
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { (_) in
                            hud.remove()
                        }, onError: { [weak self] (error) in
                            FavoriteDetailControler.logger.error("delete favorite failed", error: error)
                            if let view = self?.targetVC.view {
                                hud.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_SaveBoxDeleteFail, on: view, error: error)
                            }
                        })
                        .disposed(by: self.disposeBag)
                })
                viewModel.navigator.present(alertController, from: self.targetVC)
            }
        }

        adapter.addCancelItem(title: BundleI18n.LarkChat.Lark_Legacy_Cancel)

        viewModel.navigator.present(actionSheet, from: self.targetVC)

        return EmptyResponse()
    }
}
