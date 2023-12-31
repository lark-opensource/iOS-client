//
//  CreateTeamTask.swift
//  LarkAccount
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import LarkContainer
import RxSwift
import LarkAccountInterface

class CreateTeamTask: AsyncBootTask, Identifiable { // user:checked (boottask)
    static var identify = "CreateTeamTask"

    @Provider private var launcher: Launcher

    private let disposeBag = DisposeBag()

    override var runOnlyOnceInUserScope: Bool { return false }

    override func execute(_ context: BootContext) {
        let onLaunchGuide = false
        launcher.updateOnLaunchGuide(onLaunchGuide)
        let isRollbackLogout = context.isRollbackLogout
        context.isRollbackLogout = false
        let conf = LoginConf(
            register: true,
            fromLaunchGuide: context.isBootFromGuide,
            isRollbackLogout: isRollbackLogout
        )
        launcher.register(
            conf: conf,
            window: context.window
        )
        .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.end()
        }).disposed(by: disposeBag)
    }
}
