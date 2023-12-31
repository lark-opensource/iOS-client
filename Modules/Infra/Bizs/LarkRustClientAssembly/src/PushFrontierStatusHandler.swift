//
//  PushFrontierStatusHandler.swift
//  LarkRustClientAssembly
//
//  Created by su on 2022/5/25.
//

import Foundation
import RustPB
import LarkRustClient
import UIKit
import EENavigator
import LarkDebug

final class PushFrontierStatusHandler: BaseRustPushHandler<Basic_V1_PushFrontierStatus> {

    private var alerts = [UIViewController]()
    private var currentAlert: UIViewController?

    override func doProcessing(message: Basic_V1_PushFrontierStatus) {
        if LarkDebug.appCanDebug() {
            DispatchQueue.main.async {
                let messageContent = String(data: message.data, encoding: .utf8) ?? ""
                let alert = UIAlertController(
                    title: "PushFrontierStatus",
                    message: "Frontier-\(message.stage)-\(message.status): \(messageContent)",
                    preferredStyle: .alert
                )
                self.alerts.append(alert)
                self.showAlert()
            }
        }
    }

    private func showAlert() {
        guard currentAlert == nil, !alerts.isEmpty else { return }
        let alert = alerts.removeFirst()
        currentAlert = alert
        (Navigator.shared.mainSceneWindow ?? UIApplication.shared.keyWindow)?.rootViewController?.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            alert.dismiss(animated: true) {
                self.currentAlert = nil
                self.showAlert()
            }
        }
    }
}
