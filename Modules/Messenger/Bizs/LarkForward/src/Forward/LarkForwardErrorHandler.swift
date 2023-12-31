//
//  LarkForwardErrorHandler.swift
//  LarkForward
//
//  Created by qihongye on 2021/2/8.
//

import UIKit
import Foundation
import UniverseDesignToast
import LarkSDKInterface
import EENavigator
import LarkAlertController
import LarkContainer

public func shareErrorHandler(userResolver: UserResolver, hud: UDToast, on fromVC: UIViewController, error: Error) {
    baseErrorHandler(userResolver: userResolver,
                     hud: hud,
                     on: fromVC,
                     error: error,
                     defaultErrorMessage: BundleI18n.LarkForward.Lark_Legacy_ShareFailed)
}

public func forwardErrorHandler(userResolver: UserResolver, hud: UDToast, on fromVC: UIViewController, error: Error) {
    baseErrorHandler(userResolver: userResolver,
                     hud: hud,
                     on: fromVC,
                     error: error,
                     defaultErrorMessage: BundleI18n.LarkForward.Lark_Legacy_ChatViewForwardingFailed)
}

public func shareExtensionErrorHandler(userResolver: UserResolver, hud: UDToast, on fromVC: UIViewController, error: Error) {
    baseErrorHandler(userResolver: userResolver,
                     hud: hud,
                     on: fromVC,
                     error: error,
                     defaultErrorMessage: BundleI18n.LarkForward.Lark_Legacy_ShareExtensionReadDataError)
}

public func forwardComponentErrorHandler(userResolver: UserResolver, hud: UDToast, on fromVC: UIViewController, error: Error) {
    forwardComponentBaseErrorHandler(userResolver: userResolver,
                                     hud: hud,
                                     on: fromVC,
                                     error: error,
                                     defaultErrorMessage: BundleI18n.LarkForward.Lark_Legacy_ChatViewForwardingFailed)
}

@inline(__always)
func baseErrorHandler(userResolver: UserResolver, hud: UDToast, on fromVC: UIViewController, error: Error, defaultErrorMessage: String, defaultHandler: (() -> Void)? = nil) {
    if let error = error.underlyingError as? APIError {
        switch error.type {
        case .banned(let message):
            if let window = fromVC.view.window {
                UDToast.showFailure(with: message, on: window, error: error)
            }
        case .forbidPutP2PChats(let message):
            let alertController = LarkAlertController()
            alertController.setContent(text: message)
            alertController.addButton(text: BundleI18n.LarkForward.Lark_Legacy_ApplicationPhoneCallTimeButtonKnow)
            userResolver.navigator.present(alertController, from: WindowTopMostFrom(vc: fromVC))
            hud.remove()
        case .externalCoordinateCtl, .targetExternalCoordinateCtl:
            if let window = fromVC.view.window {
                hud.showFailure(
                    with: BundleI18n.LarkForward.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission,
                    on: window, error: error
                )
            }
        // 联系人需求：产品规定，转发时被屏蔽不弹toast
        case .collaborationAuthFailedBeBlocked:
            hud.remove()
        default:
            if let window = fromVC.view.window {
                hud.showFailure(
                    with: defaultErrorMessage,
                    on: window, error: error
                )
            }
        }
        return
    }
    if let defaultHandler = defaultHandler {
        defaultHandler()
    } else if let window = fromVC.view.window {
        hud.showFailure(with: defaultErrorMessage, on: window, error: error)
    }
}

func forwardComponentBaseErrorHandler(userResolver: UserResolver, hud: UDToast, on fromVC: UIViewController, error: Error, defaultErrorMessage: String, defaultHandler: (() -> Void)? = nil) {
    guard let window = fromVC.view.window else { return }
    if let error = error.underlyingError as? APIError {
        switch error.type {
        case .banned(let message), .forwardThreadTooLargeFail(let message):
            hud.showFailure(with: message, on: window, error: error)
        case .forbidPutP2PChats(let message):
            let alertController = LarkAlertController()
            alertController.setContent(text: message)
            alertController.addButton(text: BundleI18n.LarkForward.Lark_Legacy_ApplicationPhoneCallTimeButtonKnow)
            userResolver.navigator.present(alertController, from: WindowTopMostFrom(vc: fromVC))
            hud.remove()
        case .externalCoordinateCtl, .targetExternalCoordinateCtl:
            hud.showFailure(with: BundleI18n.LarkForward.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission, on: window, error: error)
        // 联系人需求：产品规定，转发时被屏蔽不弹toast
        case .collaborationAuthFailedBeBlocked:
            hud.remove()
        // 外部自行处理，errorHandler不处理
        case .forwardThreadReachLimit(_):
            hud.remove()
        default:
            if let window = fromVC.view.window {
                hud.showFailure(
                    with: defaultErrorMessage,
                    on: window, error: error
                )
            }
        }
        return
    }
    if let defaultHandler = defaultHandler {
        defaultHandler()
    } else if let window = fromVC.view.window {
        hud.showFailure(with: defaultErrorMessage, on: window, error: error)
    }
}
