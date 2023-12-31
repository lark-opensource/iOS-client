//
//  SilentModeApplicationDelegate.swift
//  LarkBaseService
//
//  Created by aslan on 2022/9/15.
//

import Foundation
import Homeric
import AppContainer
import Swinject
import RxSwift
import LKCommonsTracker
import LarkAccountInterface
import LarkSetting
import AudioToolbox
import LarkContainer

public final class SilentModeApplicationDelegate: ApplicationDelegate {
    static public let config = Config(name: "SilentMode", daemon: true)

    private var firstTime = true

    required public init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message: DidBecomeActive) in
            guard let `self` = self else { return }
            if !self.firstTime {
                /// 排除掉冷启动，冷启动通过SilentModeTask上报
                self.didBecomeActive(message)
            } else {
                self.firstTime = false
            }
        }
    }

    private func didBecomeActive(_ message: DidBecomeActive) {
        self.trackSilentMode()
    }

    public func trackSilentMode() {
        @Injected var passport: PassportService // Global
        // 特定环境下的静音检查，可以使用当前用户判断
        guard let user = passport.foregroundUser, user.tenant.isByteDancer else { return }
        guard FeatureGatingManager.shared.featureGatingValue(with: "lark.core.notification.status") else { return }
        detectMuteModeSwitch()
    }

    private func detectMuteModeSwitch() {
        let interval = Date.timeIntervalSinceReferenceDate
        var soundId: SystemSoundID = 1
        // swiftlint:disable all
        if let soundUrl = BundleConfig.LarkBaseServiceBundle.url(forResource: "s_m_d", withExtension: "aiff"),
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId) == kAudioServicesNoError {
        // swiftlint:enable all
            var yes: UInt32 = 1
            AudioServicesSetProperty(kAudioServicesPropertyIsUISound,
                                     UInt32(MemoryLayout.size(ofValue: soundId)),
                                     &soundId,
                                     UInt32(MemoryLayout.size(ofValue: yes)),
                                     &yes)
            AudioServicesPlaySystemSoundWithCompletion(soundId) {
                let elapsed = Date.timeIntervalSinceReferenceDate - interval
                // 检测回调时间，如果很短说明是在静音模式下
                let isMute = elapsed < 0.1
                Tracker.post(TeaEvent(Homeric.PUBLIC_NOTIFICATION_VIEW, params: [
                    "is_mute": isMute
                ]))
            }
        }
    }
}
