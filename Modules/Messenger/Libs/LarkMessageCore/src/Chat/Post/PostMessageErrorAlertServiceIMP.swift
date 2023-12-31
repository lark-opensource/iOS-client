//
//  PostMessageErrorAlertServiceIMP.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/2/7.
//

import Foundation
import UIKit
import LarkModel
import LarkMessengerInterface
import LarkSDKInterface
import EENavigator
import LarkAlertController
import LarkContainer
import LarkSendMessage

class PostMessageErrorAlertServiceIMP: PostMessageErrorAlertService {
    private let sendSevice: PostSendService
    private let nav: Navigatable
    init(sendSevice: PostSendService, nav: Navigatable) {
        self.sendSevice = sendSevice
        self.nav = nav
    }
    func showResendAlertFor(error: Error?, message: Message, fromVC: UIViewController) {
        showAlertFor(error: error, fromVC: fromVC) { [weak self] in            self?.sendSevice.resend(message: message)
        }
    }

    func showResendAlertForThread(error: Error?,
                            message: ThreadMessage,
                                  fromVC: UIViewController) {
        showAlertFor(error: error, fromVC: fromVC) { [weak self] in
            self?.sendSevice.resend(thread: message, to: .threadChat)
        }
    }
    func showAlertFor(error: Error?, fromVC: UIViewController, resendCallBack: (() -> Void)?) {
        guard let apiError = error?.underlyingError as? APIError else {
            return
        }
        if case .invalidMedia(_) = apiError.type {
            let alertController = LarkAlertController()
            alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_IM_RecalledPicsVideosExceedStorageTime_Title)
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_RecalledPicsVideosExceedStorageTime_Send_Button, dismissCompletion: {
                resendCallBack?()
            })
            self.nav.present(alertController, from: fromVC)
        }

    }
}
