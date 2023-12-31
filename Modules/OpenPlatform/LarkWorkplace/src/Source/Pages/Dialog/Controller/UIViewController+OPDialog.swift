//
//  UIViewController+OPDialog.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/8/24.
//

import Foundation
import LarkUIKit
import EENavigator
import LarkNavigator
import LarkSetting
import LKCommonsLogging

protocol OperationDialogHostProtocol {
    var context: WorkplaceContext { get }
    var dialogMgr: OperationDialogMgr { get }

    var onShow: Bool { get }
}

extension OperationDialogHostProtocol where Self: UIViewController {
    func wp_operationDialogProduce(completion: ((_ needShow: Bool) -> Void)?) {
        let notificationOn = context.configService.fgValue(for: .notificationOn)

        context.trace.info("operation dialog produce", additionalData: [
            "notificationOn": "\(notificationOn)",
            "isPad": "\(Display.pad)",
        ])

        // iPad 暂时先不支持
        if Display.pad {
            completion?(false)
            return
        }

        if !notificationOn {
            completion?(false)
            return
        }

        dialogMgr.getOperatingNotifications { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                self.context.trace.info("get operation notification success", additionalData: [
                    "onShow": "\(self.onShow)"
                ])
                guard self.onShow else {
                    completion?(false)
                    return
                }

                completion?(true)
                let body = OperationDialogBody(
                    trace: self.context.trace, dialogData: data, delegate: self
                )
                self.context.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepare: { vc in
                        vc.wp_modalStyle = .pop
                }, animated: true)
                self.dialogMgr.ackOperatingNotification(data, callback: nil)
            case .failure(let err):
                self.context.trace.error("get operation notificaiton failed", error: err)
                completion?(false)
            }
        }
    }
}

extension UIViewController: OperationDialogControllerDelegate {
    func onImageDialogClick(_ vc: OperationDialogController, link: String?, context: WorkplaceContext) {
        context.trace.info("on image dialog click", additionalData: [
            "link": link ?? ""
        ])
        guard let str = link, !str.isEmpty, let url = str.possibleURL() else { return }
        context.navigator.showDetailOrPush(
            url,
            context: ["from": "appcenter"],
            wrap: LkNavigationController.self,
            from: vc
        )
    }
}
