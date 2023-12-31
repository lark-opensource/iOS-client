//
//  LaunchGuideTask.swift
//  LarkLaunchGuide
//
//  Created by Meng on 2020/8/10.
//

import Foundation
import BootManager
import LarkContainer
import LarkFeatureSwitch
import LKLaunchGuide
import RxSwift
import LarkAccountInterface
import LKCommonsLogging

final class LaunchGuideTask: AsyncBootTask, Identifiable {
    static var identify = "LaunchGuideTask"

    private let disposeBag = DisposeBag()

    static let logger = Logger.log(LaunchGuideTask.self, category: "LaunchGuideTask")

    @Provider private var guideService: LaunchGuideService
    @Provider private var accountService: AccountService

    override var runOnlyOnceInUserScope: Bool { return false }

    override func execute(_ context: BootContext) {
        func skipGuide() -> Bool {
            var skip: Bool = false
            Feature.on(.onboarding).apply(
                on: {},
                off: { skip = true }
            )
            return skip
        }
        if skipGuide() {
            self.flowCheckout(.loginFlow)
            return
        }

        let showGuestGuide = false
        if !context.isRollbackLogout {
            guideService.checkShowGuide(window: context.window, showGuestGuide: showGuestGuide)
                .subscribe(onNext: { [weak self] (action) in
                    switch action {
                    case .createTeam:
                        context.isBootFromGuide = true
                        self?.flowCheckout(.createTeamFlow)
                    case .login:
                        context.isBootFromGuide = true
                        self?.flowCheckout(.loginFlow)
                    case .skip:
                        self?.flowCheckout(.loginFlow)
                    @unknown default: break
                    }
                }).disposed(by: disposeBag)
        } else {
            // 回滚登出时，订阅未销毁，且不能调用 checkShowGuide，修改rootVC
            context.isRollbackLogout = false
        }
        // 是否是回滚登出、都需要重新订阅
        // - 正常进入Launch Guide，需要注册
        // - 回滚登出时，前一个订阅已销毁，要重新生成订阅
        if !guideService.willSkip(showGuestGuide: showGuestGuide) {
            accountService.updateOnLaunchGuide(true)
            Self.logger.info("launch guide register login callback")
            accountService
                .launchGuideLogin(context: context.globelContext)
                .subscribe(onNext: { [weak self] (_) in
                    context.isBootFromGuide = true
                    Self.logger.info("check out to launchGuideLoginStage")
                    self?.flowCheckout(.launchGuideLoginFlow)
                }).disposed(by: disposeBag)
        }
    }
}
