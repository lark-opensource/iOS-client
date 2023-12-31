//
//  LoginTask.swift
//  LarkAccount
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import LarkContainer
import LarkPerf
import RxSwift
import LarkAccountInterface

class LoginTask: AsyncBootTask, Identifiable { // user:checked (boottask)
    static var identify = "LoginTask"

    @Provider private var launcher: Launcher

    override var runOnlyOnceInUserScope: Bool { return false }

    private let disposeBag = DisposeBag()

    override func execute(_ context: BootContext) {
        let onLaunchGuide = false
        launcher.updateOnLaunchGuide(onLaunchGuide)
        let isRollbackLogout = context.isRollbackLogout
        context.isRollbackLogout = false

        //准备回到登录页，先清理store
        if PassportSwitch.shared.enableUUIDAndNewStoreReset {
            launcher.resetWhenBackToLogin()
        }

        let conf = LoginConf(
            fromLaunchGuide: context.isBootFromGuide,
            isRollbackLogout: isRollbackLogout
        )
        launcher.login(
            conf: conf,
            window: context.window
            ).subscribe(onNext: { [weak self] (loginInfo) in
                guard let self = self else { return }

                //更新context信息
                let loginUserID = loginInfo.currentAccount.userID
                NewBootManager.shared.context.isSessionFirstActive = UserManager.shared.getUser(userID: loginUserID)?.isSessionFirstActive ?? false

                self.end()
            }).disposed(by: disposeBag)
    }
}
