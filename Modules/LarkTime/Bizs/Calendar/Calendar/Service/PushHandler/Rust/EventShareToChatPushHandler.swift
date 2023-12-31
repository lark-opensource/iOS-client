//
//  EventShareToChatPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/22.
//

import LarkRustClient
import LarkContainer
import RustPB
import EENavigator
import UniverseDesignToast
import CalendarFoundation

final class EventShareToChatPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: PushEventShareToChatNotification) throws {
        RustPushService.logger.info("receive PushEventShareToChatNotification")
        if let window = userResolver.navigator.mainSceneWindow {
            DispatchQueue.main.async {
                if !message.isSuccess {
                    switch ErrorType(rawValue: message.errorCode) {
                    case .invalidCipherFailedToSendMessage:
                        UDToast.showFailure(with: BundleI18n.Calendar.Calendar_KeyNoToast_CannotShare_Pop, on: window)
                    default:
                        UDToast.showFailure(with: BundleI18n.Calendar.Calendar_ChatFindTime_FailedtoShare, on: window)
                    }
                } else {
                    UDToast.showSuccess(with: I18n.Calendar_Share_SucTip, on: window)
                }
            }
        }
    }
}
