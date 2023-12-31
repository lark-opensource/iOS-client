//
//  ObservePasteboardLauncherDelegate.swift
//  LarkBaseService
//
//  Created by 赵冬 on 2020/4/22.
//

import Foundation
import Swinject
import LarkShareToken
import LarkAccountInterface
import LKCommonsLogging
import RunloopTools
import LarkReleaseConfig
import LarkFeatureGating
import RxSwift
import LarkEnv
import LarkContainer

/// doc: https://bytedance.feishu.cn/docs/doccnz5P4v4AVNViRTkvCNdBb7b#

public final class ObservePasteboardLauncherDelegate: LauncherDelegate, PassportDelegate {
    public let name: String = "ObservePasteboardLauncherDelegate"
    static let logger = Logger.log(
        ObservePasteboardLauncherDelegate.self,
        category: "ObservePasteboardLauncherDelegate"
    )
    private var isDoneAddObserver = false
    private let resolver: Resolver
    private let disposeBag = DisposeBag()
    private var isFirstLaunch: Bool = true
    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func userDidOnline(state: PassportState) {
        switch state.action {
        case .login: afterLoginSucceded(user: state.user)
        case .switch: afterSwitchSuccess(user: state.user)
        default: break
        }
    }
    public func afterLoginSucceded(_ context: LauncherContext) {
        let user = context.currentUserID.flatMap {
            try? Container.shared.getUserResolver(userID: $0).resolve(assert: PassportUserService.self).user
        }
        assert(user != nil, "should have user after login!!")
        afterLoginSucceded(user: user)
    }
    func afterLoginSucceded(user: User?) {
        ObservePasteboardLauncherDelegate.logger.info("afterLoginSucceded")
        // 海外版无分享口令
        guard ReleaseConfig.releaseChannel != "Oversea" else { return }
        // 国内动态环境是海外的也禁掉
        guard user?.isChinaMainlandGeo == true else {
            ObservePasteboardLauncherDelegate.logger.info("internal dynamic environment is isOversea")
            return
        }
        RunloopDispatcher.shared.addTask(priority: .low, scope: .container) {
            let shareTokenEnable = LarkFeatureGating.shared.getFeatureBoolValue(for: .shareTokenEnable)
            // 登陆后重新去判断是否监听
            if shareTokenEnable {
                self.addObserverToObservePasteboard()
                self.tryTopostNotification()
            } else {
                self.removeObserverToObservePasteboard()
            }
        }
    }

    @Provider var passport: PassportService // Global
    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        if error == nil {
            afterSwitchSuccess(user: passport.foregroundUser)
        } else {
            ObservePasteboardLauncherDelegate.logger.error("afterSwitchAccout error", error: error)
        }
        return .just(())
    }
    func afterSwitchSuccess(user: User?) {
        ObservePasteboardLauncherDelegate.logger.info("afterSwitchAccout")
        // 海外版无分享口令
        guard ReleaseConfig.releaseChannel != "Oversea" else { return }
        // 国内动态环境是海外的也禁掉
        guard user?.isChinaMainlandGeo == true else {
            ObservePasteboardLauncherDelegate.logger.info("internal dynamic environment is isOversea")
            return
        }
        RunloopDispatcher.shared.addTask(priority: .low, scope: .container) {
            // 切换租户后重新去判断是否监听
            let shareTokenEnable = LarkFeatureGating.shared.getFeatureBoolValue(for: .shareTokenEnable)
            if shareTokenEnable {
                self.addObserverToObservePasteboard()
            } else {
                self.removeObserverToObservePasteboard()
            }
        }
    }

    // NOTE: PassportDelegate不再暴露beforeLogin，登录前会缺失对应的监听..
    public func beforeLogin(_ context: LauncherContext, onLaunchGuide: Bool) {
        ObservePasteboardLauncherDelegate.logger.info("beforeLogin")
        // 海外版无分享口令
        guard ReleaseConfig.releaseChannel != "Oversea" else { return }
        guard !onLaunchGuide else {
            ObservePasteboardLauncherDelegate.logger.info("is on luanch gudie")
            return
        }
        // 国内动态环境是海外的也禁掉
        guard passport.foregroundUser?.isChinaMainlandGeo == true else {
            ObservePasteboardLauncherDelegate.logger.info("internal dynamic environment is isOversea")
            return
        }
        RunloopDispatcher.shared.addTask(priority: .low, scope: .container) {
            self.addObserverToObservePasteboard()
            self.tryTopostNotification()
        }
    }

    private func tryTopostNotification() {
        if self.isFirstLaunch {
            self.isFirstLaunch = false
        } else {
            NotificationCenter.default.post(
                name: ObservePasteboardManager.Notification.startToObservePasteboard,
                object: nil,
                userInfo: nil
            )
        }
    }

    func addObserverToObservePasteboard() {
        guard self.isDoneAddObserver == false else { return }
        ObservePasteboardLauncherDelegate.logger.info("addObserverToObservePasteboard")
        NotificationCenter.default.rx
        .notification(ObservePasteboardManager.Notification.startToObservePasteboard)
        .throttle(ObservePasteboardManager.throttle, scheduler: MainScheduler.instance)
        .subscribe(onNext: { _ in
            ObservePasteboardLauncherDelegate.logger.info("action startToObservePasteboard")
            ShareTokenManager.shared.parsePasteboardToCheckWhetherOpenTokenAlert()
        }).disposed(by: self.disposeBag)
        self.isDoneAddObserver = true
    }

    func removeObserverToObservePasteboard() {
        guard self.isDoneAddObserver == true else { return }
        ObservePasteboardLauncherDelegate.logger.info("removeObserverToObservePasteboard")
        NotificationCenter.default.removeObserver(
            self,
            name: ObservePasteboardManager.Notification.startToObservePasteboard,
            object: nil)
        self.isDoneAddObserver = false
    }
}
