//
//  CallKitApplicationDelegate.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/16.
//

import Foundation
import ByteViewCommon
import AppContainer
import Intents
import ByteViewUI
import LarkContainer
import Swinject
import LarkAccountInterface
import EENavigator
import ByteView
import ByteViewInterface

final class CallKitApplicationDelegate: ApplicationDelegate {
    static let config = Config(name: "ByteView.CallKit", daemon: true)

    init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.handleContinueUserActivity(message)
        }
    }

    private func handleContinueUserActivity(_ message: ContinueUserActivity) {
        let activity = message.userActivity
        let activityType = activity.activityType
        guard activityType == "INStartCallIntent" || activityType == "INStartVideoCallIntent" || activityType == "INStartAudioCallIntent",
              let intent = activity.interaction?.intent else {
            return
        }
        if #available(iOS 13.0, *) {
            if let callIntent = intent as? INStartCallIntent {
                self.processPersonHandle(callIntent.contacts?.first?.personHandle)
                return
            }
        }
        switch intent {
        case let callIntent as INStartVideoCallIntent:
            self.processPersonHandle(callIntent.contacts?.first?.personHandle)
        case let callIntent as INStartAudioCallIntent:
            self.processPersonHandle(callIntent.contacts?.first?.personHandle)
        default:
            break
        }
    }

    private func processPersonHandle(_ handle: INPersonHandle?) {
        do {
            guard let userId = try Container.shared.resolve(assert: PassportService.self).foregroundUser?.userID else { return }
            let resolver = try Container.shared.getUserResolver(userID: userId)
            let navigator = resolver.navigator
            let meeting = try resolver.resolve(assert: MeetingService.self).currentMeeting
            let meetingId = CallKitLauncher.processPersonHandle(handle, currentUserId: userId)
            if let meetingId, let meeting, meeting.isActive, meetingId != meeting.meetingId,
               let from = navigator.mainSceneTopMost {
                Logger.getLogger("Meeting.CallKit").info("processPersonHandle: gotoTab, meetingId = \(meetingId)")
                let body = MeetingTabBody(source: .callkit, action: .detail, meetingID: meetingId)
                navigator.present(body: body, from: from)
            }
        } catch {
            Logger.getLogger("Meeting.CallKit").info("processPersonHandle failed: \(error)")
        }
    }
}
