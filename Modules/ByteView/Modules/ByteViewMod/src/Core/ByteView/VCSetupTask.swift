//
//  VCSetupBootTask.swift
//  ByteViewMod
//
//  Created by kiri on 2021/9/26.
//

import Foundation
import BootManager
import LarkContainer
import ByteView
import ByteViewCommon
import ByteViewSetting
import ByteViewNetwork
import ByteViewTracker
import NotificationUserInfo
import LarkMedia
import LarkStorage
import LarkAccountInterface
import LarkSetting
#if canImport(ByteViewDebug)
import ByteViewDebug
#endif
#if LarkMod
import LarkPerf
#endif

final class VCSetupTask: UserFlowBootTask, Identifiable {
    static var identify: TaskIdentify = "ByteView.VCSetupTask"

    override func execute() throws {
        MonitorUtil.run("VCSetupBootTask") {
            #if LarkMod
            let isFastLogin = context.isFastLogin
            if isFastLogin { AppStartupMonitor.shared.start(key: .byteviewSDK) }
            #endif
            ByteViewPassportDelegate.shared.onBootTask(userResolver: userResolver)
            DispatchQueue.global().asyncAfter(deadline: .now()) {
                self.runBackgroundTasks()
            }
            self.trackBootTask()
            #if LarkMod
            if isFastLogin { AppStartupMonitor.shared.end(key: .byteviewSDK) }
            #endif
        }
    }

    private func trackBootTask() {
        Queue.tracker.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
            guard let context = self?.context else { return }
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                VCTracker.post(name: .client_notification_settings, params: settings.trackParams)
            }

            guard context.isFastLogin, !context.isSwitchAccount,
                  let notification = context.launchOptions?[.remoteNotification] as? [String: Any],
                  let extra = UserInfo(dict: notification)?.extra, extra.type == .video,
                  let videoContent = extra.content as? VideoContent, let data = videoContent.extraStr.data(using: .utf8),
                  let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let meetingId = dict["meeting_id"] as? String, !meetingId.isEmpty else {
                return
            }

            let interactiveId = dict["interactive_id"] as? String ?? ""
            let launchTime = LarkByteViewPreloader.launchTime
            VCTracker.post(name: .vc_apns_ringing_launch, params: [
                "meeting_id": meetingId, "interactive_id": interactiveId,
                // nolint-next-line: magic number
                "launch_time": -Int(launchTime.timeIntervalSinceNow * 1_000)
            ], time: launchTime)
        }
    }

    private func runBackgroundTasks() {
        MonitorUtil.run("setup MediaMutex") {
            LarkMediaManager.shared.setDependency(try userResolver.resolve(assert: MediaMutexDependency.self))
        }

        MonitorUtil.run("start MeetingNotifyService") {
            let params = MeetingNotifyStartParamsImpl(userResolver: userResolver)
            try userResolver.resolve(assert: MeetingNotifyService.self).start(params)
        }

        MonitorUtil.run("start CurrentMeetingService") {
            /// start listener for enter/leave meeting
            _ = try userResolver.resolve(assert: CurrentMeetingService.self)
        }

        MonitorUtil.run("setup ParticipantService") {
            ParticipantService.setDefaultStrategy { [weak userResolver] key in
                guard let r = userResolver, key.userId == r.userID else { return nil }
                return DefaultParticipantStrategy(userResolver: r)
            }
        }
        #if canImport(ByteViewDebug)
        MonitorUtil.run("setup ByteViewDebug") {
            DebugAssembler.setup(dependency: DebugDependencyImpl(userResolver: userResolver))
        }
        #endif
    }
}

private extension UNNotificationSettings {
    var trackParams: TrackParams {
        var settings: TrackParams = [
            "authorizationStatus": authorizationStatus.rawValue,
            "soundSetting": soundSetting.rawValue,
            "badgeSetting": badgeSetting.rawValue,
            "alertSetting": alertSetting.rawValue,
            "notificationCenterSetting": notificationCenterSetting.rawValue,
            "lockScreenSetting": lockScreenSetting.rawValue,
            "carPlaySetting": carPlaySetting.rawValue,
            "alertStyle": alertStyle.rawValue
        ]
        if #available(iOS 15.2, *) {
            let iOS15Settings = [
                "criticalAlertSetting": criticalAlertSetting.rawValue,
                "announcementSetting": announcementSetting.rawValue,
                "timeSensitiveSetting": timeSensitiveSetting.rawValue,
                "scheduledDeliverySetting": scheduledDeliverySetting.rawValue,
                "directMessagesSetting": directMessagesSetting.rawValue
            ]
            settings.updateParams(iOS15Settings)
        }
        return settings
    }
}

private final class MeetingNotifyStartParamsImpl: MeetingNotifyServiceStartParams {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    var userId: String {
        userResolver.userID
    }

    var lastMeetingId: String? {
        KVStores.udkv(space: .user(id: userId), domain: Domain.biz.byteView.child("Core")).string(forKey: "lastlyMeetingId")
    }

    var httpClient: HttpClient? {
        try? userResolver.resolve(assert: HttpClient.self)
    }

    var isForegroundUser: Bool {
        (try? userResolver.resolve(assert: PassportService.self).foregroundUser?.userID) == self.userId
    }

    var latestTerminationType: TerminationType {
        do {
            let service = try userResolver.resolve(assert: TerminationMonitor.self)
            return service.latestTerminationType
        } catch {
            return .unknown
        }
    }

    func cleanLastMeetingId() {
        KVStores.udkv(space: .user(id: userId), domain: Domain.biz.byteView.child("Core")).removeValue(forKey: "lastlyMeetingId")
    }
}

private final class DefaultParticipantStrategy: ParticipantStrategy {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    lazy var isShowAnotherNameEnabled: Bool = {
        do {
            let fg = try userResolver.resolve(assert: FeatureGatingService.self)
            return fg.staticFeatureGatingValue(with: .init(stringLiteral: "lark.chatter.name_with_another_name_p2"))
        } catch {
            return false
        }
    }()

    func updateParticipant(_ participant: ParticipantUserInfo) -> ParticipantUserInfo {
        if var user = participant.user {
            user.displayName = displayNameByFG(user: user)
            var newUser: ParticipantUserInfo = .user(user)
            newUser.pid = participant.pid
            return newUser
        }
        return participant
    }

    private func displayNameByFG(user: ByteViewNetwork.User) -> String {
        if let inMeetingName = user.inMeetingName, !inMeetingName.isEmpty {
            return inMeetingName
        } else if let nickName = user.nickName, !nickName.isEmpty {
            return nickName
        } else if !user.alias.isEmpty {
            return user.alias
        } else if !user.anotherName.isEmpty && isShowAnotherNameEnabled {
            return user.anotherName
        } else {
            return user.name
        }
    }
}

#if canImport(ByteViewDebug)
final class DebugDependencyImpl: ByteViewDebug.DebugDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    var userId: String {
        userResolver.userID
    }

    var setting: UserSettingManager? {
        try? userResolver.resolve(assert: UserSettingManager.self)
    }

    var storage: ByteViewCommon.LocalStorage? {
        LocalStorageImpl(space: .user(id: userId))
    }

}
#endif
