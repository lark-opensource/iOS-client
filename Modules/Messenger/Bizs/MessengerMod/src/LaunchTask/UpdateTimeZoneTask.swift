//
//  UpdateTimeZoneTask.swift
//  LarkMessenger
//
//  Created by KT on 2020/7/2.
//

import UIKit
import RxSwift
import Foundation
import BootManager
import LarkContainer
import LarkSDKInterface
import LarkFeatureGating
import LarkCore
import UniverseDesignDialog
import UniverseDesignColor
import EENavigator
import LKCommonsLogging
import LarkSetting

final class NewUpdateTimeZoneTask: UserFlowBootTask, Identifiable {
    private static let logger = Logger.log(NewUpdateTimeZoneTask.self, category: "TimeZoneChangeAlert")
    static var identify = "UpdateTimeZoneTask"

    @ScopedProvider private var chatterAPI: ChatterAPI?
    @ScopedProvider private var configurationAPI: ConfigurationAPI?
    @ScopedProvider private var fgService: FeatureGatingService?

    override var deamon: Bool { return true }

    private let disposeBag = DisposeBag()

    override var scheduler: Scheduler { return .async }

    private lazy var timeZoneEnable: Bool = {
        fgService?.staticFeatureGatingValue(with: "im.setting.external_display_timezone") ?? false
    }()
    private var lastClickedTime: Date?
    //判断app是否需要重启的变量
    private var needRestart: Bool = false
    private var alertTimer: Timer?
    private var currentTimeZone = TimeZone.current

    override func execute(_ context: BootContext) {
        currentTimeZone = TimeZone.current

        /// https://bytedance.feishu.cn/docx/doxcnOCtKIhoiR6gu5kB0KwYdHb
                /// 此需求fg开启, 无需端上处理Chatter时区变化
        if timeZoneEnable == false {
            NotificationCenter.default.removeObserver(self, name: UIApplication.significantTimeChangeNotification, object: nil)
            // 13. 更新 chatter 时区信息
            self.chatterAPI?.updateTimezone(timezone: TimeZone.current.identifier)
                .subscribe()
                .disposed(by: self.disposeBag)
            // 14. 时区信息变化通知
            NotificationCenter.default.rx
                .notification(UIApplication.significantTimeChangeNotification)
                .flatMap({ [weak self] _ -> Observable<Void> in
                    guard let self = self else { return .just(()) }
                    return self.chatterAPI?.updateTimezone(timezone: TimeZone.current.identifier) ?? .empty()
                })
                .subscribe()
                .disposed(by: self.disposeBag)
        }

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil)
        // 更新系统时区
        configurationAPI?.updateSysytemTimezone(TimeZone.current.identifier)
            .subscribe()
            .disposed(by: self.disposeBag)
        // 监听系统时区变化
        NotificationCenter.default.rx.notification(.NSSystemTimeZoneDidChange)
            .flatMap({ [weak self] _ -> Observable<Void> in
                guard let self = self else { return .just(()) }
                Self.logger.info("NSSystemTimeZoneDidChange notification triggered")
                self.showRestartAlert()
                return self.configurationAPI?.updateSysytemTimezone(TimeZone.current.identifier) ?? .empty()
            })
            .subscribe()
            .disposed(by: self.disposeBag)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground),
                                                       name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc
    func appWillEnterForeground() {
        if let clickedTime = lastClickedTime, needRestart {
            Self.logger.info("app Will Enter Foreground, \(Date()), \(clickedTime)")
            if Date().timeIntervalSince(clickedTime) >= 7200 {
                stopTimerAndShowAlert()
            }
        } else {
            return
        }
    }

    private func showRestartAlert() {
        if TimeZone.current.secondsFromGMT() == currentTimeZone.secondsFromGMT() {
            return
        }
        let title = BundleI18n.LarkCore.Lark_Core_TimeZoneChanged_Title
        let message = BundleI18n.LarkCore.Lark_Core_TimeZoneChanged_Desc()
        let alertController = UDDialog()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        alertController.addSecondaryButton(text: BundleI18n.LarkCore.Lark_Core_TimeZoneChanged_Later_Button, dismissCompletion: { [weak self] in
            Self.logger.info("Clicked later button")

            self?.lastClickedTime = Date()
            self?.needRestart = true
            self?.setupRestartTimer()
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkCore.Lark_Core_TimeZoneChanged_Restart_Button, dismissCompletion: { [weak self] in
            Self.logger.info("Clicked restart button")
            self?.restartAppImmediately()
        })
        guard let keyWindow = userResolver.navigator.mainSceneWindow ?? UIApplication.shared.keyWindow else {
            Self.logger.warn("No keyWindow found")
            return
        }

        userResolver.navigator.present(alertController, from: keyWindow)
    }

    // 停止计时
    @objc
    private func stopTimerAndShowAlert() {
        if let alertTimer = alertTimer {
            alertTimer.invalidate() //销毁timer
            self.alertTimer = nil
            Self.logger.info("timer stopped")
            self.needRestart = false
            showRestartAlert()
        }
    }

    private func setupRestartTimer() {
        let timer = Timer(fireAt: Date().addingTimeInterval(7200), // Fire after 2 hours from now
                            interval: 0,
                            target: self,
                          selector: #selector(stopTimerAndShowAlert),
                          userInfo: nil,
                            repeats: false)
        self.alertTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    private func restartAppImmediately() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var exitSel: Selector { Selector(["terminate", "With", "Success"].joined()) }
            UIApplication.shared.perform(exitSel, on: Thread.main, with: nil, waitUntilDone: false)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        Self.logger.info("task deinit")
    }
}
