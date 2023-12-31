//
//  RestrictedMessageHandler.swift
//  LarkMessageCore
//
//  Created by zigeng on 2021/12/15.
//
import UIKit
import Foundation
import LarkModel
import RxSwift
import RustPB
import LarkMessageBase
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer
import LarkCore
import UniverseDesignToast
import EENavigator
import LarkUIKit
import UniverseDesignActionPanel
import UniverseDesignDialog

public final class RestrictedMessageHandler {
    private let disposeBag = DisposeBag()
    private var messageAPI: MessageAPI?
    private weak var targetVC: UIViewController?
    private let nav: Navigatable

    public init(messageAPI: MessageAPI?, targetVC: UIViewController, nav: Navigatable) {
        self.targetVC = targetVC
        self.messageAPI = messageAPI
        self.nav = nav
    }

    public func handle(message: Message, chat: Chat, params: [String: Any], onFinish: ((Error?) -> Void)?) {
        guard let chatId = Int64(chat.id), let messageId = Int64(message.id) else {
            return
        }
        restrictAction(messageId: messageId, chatId: chatId, onFinish: onFinish)
    }

    func setRestrict(messageId: Int64, chatId: Int64, onFinish: ((Error?) -> Void)?) -> (() -> Void) {
        return { [messageId, chatId, weak self] in
            guard let view = self?.targetVC?.view else { return }
            let hud = UDToast.showLoading(on: view)
            self?.messageAPI?.updateRestrictedMessage(chatId: chatId,
                                               messageId: messageId,
                                               isRestricted: true)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    hud.remove()
                    guard let view = self?.targetVC?.view else { return }
                    UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_IM_MessageSetAsRestricted_Toast, on: view)
                    onFinish?(nil)
                }, onError: { error in
                    if let message = (error.underlyingError as? APIError)?.displayMessage {
                        hud.remove()
                        guard let view = self?.targetVC?.view else { return }
                        UDToast.showFailure(with: message, on: view, error: error)
                    }
                    onFinish?(error)
                }).disposed(by: self?.disposeBag ?? DisposeBag())
        }
    }

    func restrictAction(messageId: Int64, chatId: Int64, onFinish: ((Error?) -> Void)?) {
        guard let targetVC = self.targetVC else { return }
        if Display.phone {
            let source = UDActionSheetSource(sourceView: targetVC.view, sourceRect: targetVC.view.bounds, arrowDirection: .up)
            let actionsheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
            actionsheet.setTitle(BundleI18n.LarkMessageCore.Lark_IM_SetMessageAsdRestricted_Desc)
            actionsheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_IM_SetMessageAsdRestricted_Set_Button, action: setRestrict(messageId: messageId, chatId: chatId, onFinish: onFinish))
            actionsheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_IM_SetMessageAsdRestricted_Cancel_Button)
            nav.present(actionsheet, from: targetVC)
        /// iPad使用UDDialog
        } else {
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_SetMessageAsdRestricted_Title)
            dialog.setContent(text: BundleI18n.LarkMessageCore.Lark_IM_SetMessageAsdRestricted_Desc)
            dialog.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_SetMessageAsdRestricted_Set_Button,
                                      dismissCompletion: setRestrict(messageId: messageId, chatId: chatId, onFinish: onFinish))
            dialog.addCancelButton()
            nav.present(dialog, from: targetVC)
        }
    }
}

public final class CancelRestrictedMessageHandler {
    private let disposeBag = DisposeBag()
    private var messageAPI: MessageAPI?
    private weak var targetVC: UIViewController?

    public init(messageAPI: MessageAPI?, targetVC: UIViewController) {
        self.targetVC = targetVC
        self.messageAPI = messageAPI
    }

    func cancelRestrict(messageId: Int64, chatId: Int64, onFinish: ((Error?) -> Void)?) {
        guard let view = self.targetVC?.view else { return }
        let hud = UDToast.showLoading(on: view)
        self.messageAPI?.updateRestrictedMessage(chatId: chatId,
                                                 messageId: messageId,
                                                 isRestricted: false)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] _  in
            hud.remove()
            guard let view = self?.targetVC?.view else { return }
            UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_IM_MessageSetAsUnrestricted_Toast, on: view)
            onFinish?(nil)
        }, onError: { [weak self] error in
            hud.remove()
            if let message = (error.underlyingError as? APIError)?.displayMessage {
                guard let view = self?.targetVC?.view else { return }
                UDToast.showFailure(with: message, on: view, error: error)
            }
            onFinish?(error)
        }).disposed(by: self.disposeBag)
    }

    public func handle(message: Message, chat: Chat, params: [String: Any], onFinish: ((Error?) -> Void)?) {
        guard let chatId = Int64(chat.id), let messageId = Int64(message.id) else { return }
        cancelRestrict(messageId: messageId, chatId: chatId, onFinish: onFinish)
    }
}
