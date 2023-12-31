//
//  DataCorruptPushHandler.swift
//  LarkMonitor
//
//  Created by PGB on 2020/3/9.
//

import UIKit
import Foundation
import RustPB
import LarkAlertController
import EENavigator
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LKCommonsTracker
import Homeric

extension Basic_V1_PushDataCorruptResponse: PushMessage {}

final class DataCorruptPushHandler: UserPushHandler {
    
    static let logger = Logger.log(DataCorruptPushHandler.self, category: "Rust.PushHandler")
    // lint:disable lark_storage_check
    static private let safeModeConfig = UserDefaults(suiteName: "lk_safe_mode")
    static private var corruptCount = UserDefaults.standard.integer(forKey: "rust_data_corrupt_count")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    
    static private var customExceptionConfig: [String: Any]? = {
        if let config = safeModeConfig?.value(forKey: "lark_custom_exception_config") as? [String: Any],
            config["safe_mode"] != nil {
            return config["safe_mode"] as? [String: Any]
        }
        return nil
    }()
    
    static var safeModeRustDataCorruptEnable: Bool = {
        if let corruptEnable = customExceptionConfig?["lk_safe_mode_rust_data_corrupt_enable"] as? Bool {
            return corruptEnable
        }
        return false
    }()
    
    static private var safeModeRustDataCorruptCount: Int = {
        if let corruptCount = customExceptionConfig?["lk_safe_mode_rust_data_corrupt_count"] as? Int {
            return corruptCount
        }
        return 2
    }()

    func process(push message: Basic_V1_PushDataCorruptResponse) throws {
        DataCorruptPushHandler.logger.debug("Receive Push of data corruption: \(message.reason)")
        pushCenter?.post(message)

        Tracker.post(TeaEvent(Homeric.DB_DAMAGE_INFO))
        
        if (   UserDefaults.standard.bool(forKey: "rust_data_corrupt")
            && DataCorruptPushHandler.safeModeRustDataCorruptEnable
            && DataCorruptPushHandler.corruptCount >= DataCorruptPushHandler.safeModeRustDataCorruptCount) {
            UserDefaults.standard.set(false, forKey: "rust_data_corrupt")
            UserDefaults.standard.set(0, forKey: "rust_data_corrupt_count")
            NotificationCenter.default.post(name: NSNotification.Name("rust_data_corrupt"),
                                            object: nil,
                                            userInfo: nil)
            return
        }

        DispatchQueue.main.async {
            guard let kw = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
                DataCorruptPushHandler.logger.error("Can't find keyWindow, ignore alert")
                return
            }
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkMonitor.Lark_Legacy_DBDamage)
            alertController.setContent(text: BundleI18n.LarkMonitor.Lark_Legacy_DBDamageRestart())

            alertController.addSecondaryButton(text: BundleI18n.LarkMonitor.Lark_Legacy_DBDamageRestartLater) {
                DataCorruptPushHandler.logger.debug("User chooses cancel for data corruption")
                Tracker.post(TeaEvent(Homeric.DB_DAMAGE_ACTION, params: [
                    "action": 0
                ]))
            }

            alertController.addPrimaryButton(text: BundleI18n.LarkMonitor.Lark_Legacy_DBDamageRestartNow) {
                DataCorruptPushHandler.logger.debug("User chooses exit for data corruption")
                Tracker.post(TeaEvent(Homeric.DB_DAMAGE_ACTION, params: [
                    "action": 1
                ]))
                exit(0)
            }
            self.userResolver.navigator.present(alertController, from: kw)
            UserDefaults.standard.set(true, forKey: "rust_data_corrupt")
            DataCorruptPushHandler.corruptCount += 1
            UserDefaults.standard.set(DataCorruptPushHandler.corruptCount, forKey: "rust_data_corrupt_count")
        }
    }
}
