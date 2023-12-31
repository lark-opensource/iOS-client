//
//  FavoriteMergeForwardDetailBarItemsGenerator.swift
//  LarkChat
//
//  Created by zc09v on 2019/7/18.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignToast
import RxSwift
import EENavigator
import LarkModel
import LarkAlertController
import LarkCore
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer

final class FavoriteMergeForwardDetailBarItemsGenerator: RightBarButtonItemsGenerator, UserResolverWrapper {
    let userResolver: UserResolver
    private let favoriteId: String
    private let message: Message
    private let favoriteAPI: FavoritesAPI
    private let disposeBag = DisposeBag()
    weak var targetVC: UIViewController?

    init(userResolver: UserResolver, message: Message, favoriteId: String, favoriteAPI: FavoritesAPI) {
        self.userResolver = userResolver
        self.favoriteId = favoriteId
        self.message = message
        self.favoriteAPI = favoriteAPI
    }

    func rightBarButtonItems() -> [UIBarButtonItem] {
        var items: [UIBarButtonItem] = []

        let deleteItem = LKBarButtonItem(image: Resources.deleteFavorite)
        deleteItem.button.addTarget(self, action: #selector(deleteButtonClick), for: .touchUpInside)
        deleteItem.button.contentHorizontalAlignment = .right
        items.append(deleteItem)

        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 18
        items.append(spacer)

        let forwardItem = LKBarButtonItem(image: Resources.forwardFavorite)
        forwardItem.button.addTarget(self, action: #selector(forwardButtonClick), for: .touchUpInside)
        forwardItem.button.contentHorizontalAlignment = .right
        items.append(forwardItem)
        return items
    }

    @objc
    private func deleteButtonClick() {
        guard let targetVC = self.targetVC else { return }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChat.Lark_Legacy_SaveBoxDeleteConfirm)
        alertController.addCancelButton()
        alertController.addDestructiveButton(text: BundleI18n.LarkChat.Lark_Legacy_Remove, dismissCompletion: {
            let hud = UDToast.showDefaultLoading(on: targetVC.view, disableUserInteraction: true)
            self.favoriteAPI.deleteFavorites(ids: [self.favoriteId])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_) in
                    hud.remove()
                    targetVC.navigationController?.popViewController(animated: true)
                }, onError: { [weak targetVC] (error) in
                    FavoriteDetailControler.logger.error("delete favorite failed", error: error)
                    if let view = targetVC?.view {
                        hud.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_SaveBoxDeleteFail, on: view, error: error)
                    }
                })
                .disposed(by: self.disposeBag)
        })
        navigator.present(alertController, from: targetVC)
    }

    @objc
    private func forwardButtonClick() {
        guard let targetVC = self.targetVC else {
            assertionFailure()
            return
        }

        let forwardbody = ForwardMessageBody(message: message, type: .favorite(favoriteId), from: .favorite, supportToMsgThread: true)
        navigator.present(
            body: forwardbody,
            from: targetVC,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }
}
