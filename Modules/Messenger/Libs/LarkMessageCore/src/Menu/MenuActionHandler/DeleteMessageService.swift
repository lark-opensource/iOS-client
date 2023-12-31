//
//  DeleteMessageService.swift
//  LarkChat
//
//  Created by liuwanlin on 2019/6/20.
//

import UIKit
import Foundation
import LarkCore
import RxSwift
import LarkActionSheet
import UniverseDesignToast
import EENavigator
import LarkUIKit
import LarkAlertController
import LarkSDKInterface
import LarkContainer

public protocol DeleteMessageService: AnyObject {
    func delete(messageIds: [String], callback: ((Bool) -> Void)?)
}

public final class DeleteMessageServiceImpl: DeleteMessageService {
    private unowned let controller: UIViewController
    private let messageAPI: MessageAPI?

    private let disposeBag = DisposeBag()
    private let nav: Navigatable
    public init(controller: UIViewController, messageAPI: MessageAPI?, nav: Navigatable) {
        self.controller = controller
        self.messageAPI = messageAPI
        self.nav = nav
    }

    public func delete(messageIds: [String], callback: ((Bool) -> Void)?) {
        let alertController = LarkAlertController()
        // 提示
        alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_Legacy_ChatDeleteTip)
        // 取消
        alertController.addSecondaryButton(
            text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel,
            dismissCompletion: { callback?(false) }
        )
        // 删除
        alertController.addDestructiveButton(
            text: BundleI18n.LarkMessageCore.Lark_Legacy_LarkDelete,
            dismissCompletion: { [weak self] in
               callback?(true)
               self?.processDelete(messageIds: messageIds)
               if messageIds.count == 1 {
                   CoreTracker.trackMessageDeleteConfirm()
               } else {
                   CoreTracker.trackMultiMessageDeleteConfirm()
               }
            }
        )
        // 弹窗
        self.nav.present(alertController, from: controller)

        if messageIds.count == 1 {
            CoreTracker.trackMessageDelete()
        } else {
            CoreTracker.trackMultiMessageDelete()
        }
    }

    private func processDelete(messageIds: [String]) {
        let hud = UDToast.showLoading(
            with: BundleI18n.LarkMessageCore.Lark_Legacy_BaseUiLoading,
            on: controller.view,
            disableUserInteraction: true
        )
        messageAPI?
            .delete(messageIds: messageIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                hud.remove()
            }, onError: { [weak controller] error in
                guard let window = controller?.view.window else { return }
                hud.showFailure(
                    with: BundleI18n.LarkMessageCore.Lark_Legacy_ChatViewFailHideMessage,
                    on: window,
                    error: error
                )
            })
            .disposed(by: self.disposeBag)
    }
}
