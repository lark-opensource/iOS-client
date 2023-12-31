//
//  ObservePasteboardApplicationDelegate.swift
//  LarkBaseService
//
//  Created by 赵冬 on 2020/4/22.
//

import Foundation
import AppContainer
import LarkShareToken
import RunloopTools
import LarkReleaseConfig
import LarkFeatureGating
import LarkAccountInterface
import LarkEnv
import LKCommonsLogging
import RxSwift
import LarkContainer

public final class ObservePasteboardApplicationDelegate: ApplicationDelegate {
    public static let config = Config(name: "ObserverPasteboardContent", daemon: true)
    private let disposeBag = DisposeBag()
    static let logger = Logger.log(
        ObservePasteboardApplicationDelegate.self,
        category: "ObservePasteboardLauncherDelegate"
    )
    private var publishSubject = PublishSubject<Void>()
    private var publishSignal: Observable<Void> { return publishSubject.asObservable() }
    @Provider private var passport: PassportService // Global

    required public init(context: AppContext) {
        publishSignal
            .throttle(ObservePasteboardManager.throttle, scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
            self?.postNotification()
        }).disposed(by: self.disposeBag)

        context.dispatcher.add(observer: self) { [weak self] (_, _: DidBecomeActive) in
            ObservePasteboardApplicationDelegate.logger.info("didBecomeActiveNotification")
            self?.publishSubject.onNext(())
        }
    }

    private func postNotification() {
        // 海外版无分享口令
        guard ReleaseConfig.releaseChannel != "Oversea" else { return }
        // 国内动态环境是海外的也禁掉

        guard passport.foregroundUser?.isChinaMainlandGeo == true else {
            ObservePasteboardApplicationDelegate.logger.info("internal dynamic environment is isOversea")
            return
        }
        RunloopDispatcher.shared.addTask(priority: .low, scope: .container) {
            // fg依赖登陆态, 未登陆直接放开
            let shareTokenEnable = LarkFeatureGating.shared.getFeatureBoolValue(for: .shareTokenEnable)
            let isLogin = self.passport.foregroundUser != nil
            if isLogin, shareTokenEnable == false {
                return
            }
            ObservePasteboardApplicationDelegate.logger.info("send Notification named startToObservePasteboard ")
            NotificationCenter.default.post(
                name: ObservePasteboardManager.Notification.startToObservePasteboard,
                object: nil,
                userInfo: nil
            )
        }
    }
}
