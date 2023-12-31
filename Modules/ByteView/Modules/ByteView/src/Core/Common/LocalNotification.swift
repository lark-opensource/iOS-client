//
//  LocalNotification.swift
//  ByteView
//
//  Created by kiri on 2020/9/29.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkLocalizations
import ByteViewNetwork

final class MeetingLocalNotificationCenter {
    static let shared = MeetingLocalNotificationCenter()

    private init() {}
    private var identifiers: [String: String] = [:]

    func showLocalNotification(_ info: VideoChatInfo, service: MeetingBasicService) {
        // show local notification
        let identifier = UNUserNotificationCenter.current().showLocalNotification(for: info, service: service)
        identifiers[info.id] = identifier
    }

    func removeLocalNotification(_ meetingId: String) {
        if let notificationId = identifiers.removeValue(forKey: meetingId) {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationId])
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
    }
}

extension UNUserNotificationCenter {
    func addLocalNotification(withIdentifier identifier: String,
                              body: String,
                              soundName: String? = nil,
                              userInfo: [AnyHashable: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = soundName.map({ UNNotificationSound(named: UNNotificationSoundName($0)) }) ?? .default
        content.userInfo = userInfo
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        add(request) { error in
            if let error = error {
                Logger.util.error("Schedule LocalNotification failed, error: \(error).")
            } else {
                Logger.util.debug("Schedule LocalNotification succeed.")
            }
        }
        Logger.util.info("Did schedule LocalNotification: \(request)")
    }

    func showLocalNotification(for info: VideoChatInfo, service: MeetingBasicService) -> String {
        let identifier = info.id
        let soundName = service.setting.customRingtone
        if service.setting.shouldShowDetails {
            service.httpClient.participantService.participantInfo(pid: .init(id: info.inviterId, type: info.inviterType), meetingId: info.id) { [weak self] ap in
                self?.addLocalNotification(
                    withIdentifier: identifier,
                    body: info.type == .meet ? I18n.View_M_InvitedToMeetingNameBraces(ap.name) : info.isVoiceCall ? I18n.View_A_IncomingVoiceCallFromNameBraces(ap.name) : I18n.View_V_IncomingVideoCallFromNameBraces(ap.name),
                    soundName: soundName)
            }
        } else {
            let noName = info.isVoiceCall ? I18n.View_A_IncomingVoiceCallNoName : I18n.View_V_IncomingVideoCallNoName
            addLocalNotification(withIdentifier: identifier, body: noName, soundName: soundName)
        }
        return identifier
    }
}
