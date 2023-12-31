//
//  AudioUtils.swift
//  LarkAudio
//
//  Created by kangkang on 2023/11/20.
//

import Foundation
import CoreTelephony
import LarkSensitivityControl
import LarkContainer
import EENavigator
import UniverseDesignDialog
import Reachability
import UniverseDesignToast
import LKCommonsLogging

// Audio的工具方法，都是计算方法，不涉及存储属性
final class AudioUtils {
    private static let logger = Logger.log(AudioUtils.self, category: "AudioUtils")
    static func checkByteViewState(userResolver: UserResolver, from: NavigatorFrom?) -> Bool {
        guard let byteViewService = (try? userResolver.resolve(assert: AudioDependency.self)), let from else { return false }
        if byteViewService.byteViewHasCurrentModule() {
            let text = byteViewService.byteViewIsRinging() ? byteViewService.byteViewInRingingCannotCallVoIPText() : byteViewService.byteViewIsInCallText()
            let alert = UDDialog()
            alert.setTitle(text: text)
            alert.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            userResolver.navigator.present(alert, from: from)
            Self.logger.error("check byteViewState false")
            return false
        }
        Self.logger.info("check byteViewState true")
        return true
    }

    static func checkCallingState(userResolver: UserResolver, from: NavigatorFrom?) -> Bool {
        guard let byteViewService = (try? userResolver.resolve(assert: AudioDependency.self)), let from else { return false }
        // 飞书内部 vc 正在运行时，不判断 CTCall
        if byteViewService.byteViewHasCurrentModule() || byteViewService.byteViewIsRinging() {
            Self.logger.info("check calling true, byteViewHasCurrentModule or byteViewIsRinging")
            return true
        }
        if let calls = AudioUtils.getCurrentCalls(), !calls.isEmpty {
            let alert = UDDialog()
            alert.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_VoiceMessageFailedToast)
            alert.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            userResolver.navigator.present(alert, from: from)
            Self.logger.info("check calling false")
            return false
        }
        Self.logger.info("check calling true")
        return true
    }

    static func checkNetworkConnection(view: UIView?) -> Bool {
        guard let reach = Reachability() else { return false }
        guard let view, let vc = AudioUtils.getViewController(view: view) else { return true }
        if reach.connection == .none {
            UDToast.showTipsOnScreenCenter(with: BundleI18n.LarkAudio.Lark_Chat_AudioToTextNetworkError, on: vc.view)
            Self.logger.error("check network connection false")
            return false
        }
        Self.logger.info("check network connection true")
        return true
    }

    static func presentFailAlert(userResolver: UserResolver, from: NavigatorFrom?) {
        guard let from else { return }
        let alert = UDDialog()
        alert.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_VoiceMessageFailedToast)
        alert.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
        userResolver.navigator.present(alert, from: from)
    }

    static func getViewController(view: UIView) -> UIViewController? {
        if let next = view.next as? UIViewController {
            return next
        } else if let next = view.next as? UIView {
            return AudioUtils.getViewController(view: next)
        }
        return nil
    }

    static func timeString(time: TimeInterval) -> String {
        // 更新时间
        let timeStr: String
        let time = Int(time)
        let second = time % 60
        let minute = time / 60
        let secondStr = String(format: "%02d", second)
        if minute == 0 {
            timeStr = "0:" + secondStr
        } else {
            timeStr = "\(minute):" + secondStr
        }
        return timeStr
    }

    static func getCurrentCalls() -> Set<CTCall>? {
        do {
            return try DeviceInfoEntry.currentCalls(
                forToken: Token(withIdentifier: "LARK-PSDA-audio_record_check_call"),
                callCenter: CTCallCenter()
            )
        } catch {
            return nil
        }
    }
}
