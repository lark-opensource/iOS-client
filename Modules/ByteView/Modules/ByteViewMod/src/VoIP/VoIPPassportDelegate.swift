//
//  VoIPManager.swift
//  ByteViewMod
//
//  Created by kiri on 2021/9/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//
import Foundation
import RunloopTools
import RxSwift
import NotificationUserInfo
import LarkAccountInterface
import LarkVoIP
import ByteViewInterface
import BootManager
import LKCommonsTracker
import LKCommonsLogging
import Homeric
import ByteViewMeeting
import LarkContainer

final class VoIPPassportDelegate: PassportDelegate {
    private static let logger = Logger.log(VoIPPassportDelegate.self, category: "VoIP.Launch")

    static let shared = VoIPPassportDelegate()

    let name: String = "VoipMoudle"
    private var disposeBag = DisposeBag()

    func stateDidChange(state: PassportState) {
        if state.action == .switch || state.action == .logout {
            resetWhenLogout()
        }
    }

    func executeBootTask(_ context: BootContext, userResolver: UserResolver) {
        disposeBag = DisposeBag()
        let userId = userResolver.userID
        // 后台启动是通过voip push拉活，目前加密通话已经去掉了voip push支持 所以无需拉取数据
        let isBackground = UIApplication.shared.applicationState == .background
        let shouldPull = !isBackground || self.isLaunchWithVoIPNotification(context.launchOptions)
        if isBackground {
            // DispatchQueue在后台跑不动，直接执行
            self._executeBootTask(shouldPull, userResolver: userResolver)
        } else {
            DispatchQueue.global().async {
                self._executeBootTask(shouldPull, userResolver: userResolver)
            }
        }
        trackApns(context: context)
    }

    private func _executeBootTask(_ shouldPull: Bool, userResolver: UserResolver) {
        if shouldPull {
            self.setupPullByStartup(userResolver: userResolver)
        }
    }

    private func resetWhenLogout() {
        if let session = MeetingManager.shared.currentSession?.toVoipInterface() {
            session.interruptCurrentVoip()
        }
        disposeBag = DisposeBag()
    }

    private func trackApns(context: BootContext) {
        guard context.isFastLogin, !context.isSwitchAccount,
              let notification = context.launchOptions?[.remoteNotification] as? [String: Any],
              let extra = UserInfo(dict: notification)?.extra, extra.type == .call,
              let content = extra.content as? CallContent, let data = content.extraStr.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let callId = dict["call_id"] as? String, !callId.isEmpty else {
            return
        }

        let launchTime = LarkByteViewPreloader.launchTime.timeIntervalSince1970
        Tracker.post(TeaEvent(Homeric.VOIP_APNS_RINGING_LAUNCH,
                              params: ["call_id": callId,
                                       "launch_time": launchTime * 1000],
                              timestamp: Timestamp(time: launchTime)))
    }

    private func isLaunchWithVoIPNotification(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let notification = launchOptions?[.remoteNotification] as? [String: Any],
              let userInfo = UserInfo(dict: notification),
              let extra = userInfo.extra, extra.type == .call else {
                  return false
              }
        return true
    }

    private func setupPullByStartup(userResolver: UserResolver) {
        guard let service = try? userResolver.resolve(assert: VoIPConfigService.self), service.isVoIPEnabled,
              let pullService = try? userResolver.resolve(assert: VoIPCallPullService.self) else { return }
        // 有数据才初始化voip service
        pullService.pullCurrentCall(sourceType: .startup)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { (call) in
                if let service = try? userResolver.resolve(assert: VoIPService.self), let call = call {
                    service.setCallModel(call: call, fromSource: .pull)
                }
            }).disposed(by: disposeBag)
    }
}
