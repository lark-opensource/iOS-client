//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by mochangxing on 2019/8/11.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import UserNotifications
import LarkNotificationServiceExtension
import LarkLocalizations
import LarkExtensionServices
import HeimdallrForExtension

private let initOnce: Void = {
    // swiftlint:disable all
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    // swiftlint:enable all
}()

final class LarkNotificationService: UNNotificationServiceExtension {
    let dispatcher: LarkNSExtensionDispatcher

    override init() {
        _ = initOnce
        dispatcher = LarkNSExtensionDispatcher()
        DispatchQueue.main.async {
            #if CRASH_TRACKER_ENABLE
            HMDInjectedInfo.default().userID = ExtensionAccountService.currentAccountID ?? ""
            HMDExtensionCrashTracker.shared().start(withGroupID: appGrounpName)
            #endif
            HMDDyldExtension.preloadDyld(withGroupID: appGrounpName)
        }
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        dispatcher.didReceive(request, withContentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() {
        dispatcher.serviceExtensionTimeWillExpire()
    }

}
