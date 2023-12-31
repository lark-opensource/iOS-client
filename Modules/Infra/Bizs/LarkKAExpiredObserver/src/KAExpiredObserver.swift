//
//  KAExpiredObserver.swift
//  LarkKAExpiredObserver-LarkKAExpiredObserverAuto
//
//  Created by ByteDance on 2022/5/27.
//

import Foundation
import LarkSetting
import OpenCombine
import UniverseDesignDialog
import EENavigator
import LarkNavigator
import UIKit
import BootManager
import AppContainer

final class KAExpiredObserver {
    struct Response: SettingDecodable{
        static var settingKey = UserSettingKey.make(userKeyLiteral: "ka_expired_force_alert_config")
        let expired: Bool
        let downloadUrl: String
    }
    var cancelBag = Set<AnyCancellable>()

    func start() {
        SettingManager.shared.observe(type: Response.self, key: Response.settingKey, decodeStrategy: .convertFromSnakeCase).sink { _ in

        } receiveValue: { [weak self] value in
            self?.showAlertIfNeeded(response: value)
        }.store(in: &cancelBag)
        observeHotreload()
    }

    func observeHotreload() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let setting = try? SettingManager.shared.setting(with: Response.self) else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.showAlertIfNeeded(response: setting)
            }
        }
    }

    func showAlertIfNeeded(response: Response) {
        guard response.expired else {
            return
        }
        guard let from = Navigator.shared.mainSceneTopMost else {
            return
        }
        guard !isShowing() else {
            return
        }
        showAlert(from: from, jumpTo: response.downloadUrl)
    }

    func showAlert(from: NavigatorFrom, jumpTo url: String) {
        guard let url = URL(string: url) else {
            return
        }
        let alert = KAUDDialog()
        alert.setContent(text: BundleI18n.LarkKAExpiredObserver.Lark_KA_AppVersionExpiredDownloadFeishuForDelightfulWorkExperience_Text)
        alert.addPrimaryButton(text: BundleI18n.LarkKAExpiredObserver.Lark_KA_AppVersionExpiredDownloadFeishuForDelightfulWorkExperience_DownloadFeishu_Button) {
            UIApplication.shared.open(url)
            return false
        } dismissCompletion: {

        }
        Navigator.shared.present(alert, from: from)
    }

    func isShowing() -> Bool {
        guard let from = Navigator.shared.mainSceneTopMost else {
            return false
        }
        return from is KAUDDialog
    }
}

final class KAUDDialog: UDDialog {

}

