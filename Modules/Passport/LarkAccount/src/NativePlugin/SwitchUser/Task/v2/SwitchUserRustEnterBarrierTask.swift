//
//  SwitchUserRustEnterBarrierTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/4/24.
//

import Foundation
import LarkAccountInterface
import RxSwift
import LarkContainer

class SwitchUserRustEnterBarrierTask: NewSwitchUserTask {

    @Provider private var rustDependency: PassportRustClientDependency // user:checked (global-resolve)

    private let disposeBag = DisposeBag()

    override func run() {

        let startTime = CACurrentMediaTime()

        // userID 内部暂不使用，先用空字符串兜底
        rustDependency.deployUserBarrier(userID: UserManager.shared.foregroundUser?.userID ?? "") { [weak self] _ in // user:current
            guard let self = self else { return }

            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustBarrierCost,
                                          categoryValueMap: [ProbeConst.duration: (CACurrentMediaTime() - startTime) * 1000],
                                          context: self.monitorContext)

            self.succCallback()
        }
    }

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void) {
        finished(.success(()))
    }
}

class SwitchUserRustEnterBarrierPreTask: SwitchUserPreTask {

    @Provider private var rustDependency: PassportRustClientDependency // user:checked (global-resolve)

    private let disposeBag = DisposeBag()

    override func run() {

        let startTime = CACurrentMediaTime()

        // userID 内部暂不使用，先用空字符串兜底
        rustDependency.deployUserBarrier(userID: UserManager.shared.foregroundUser?.userID ?? "") { [weak self] _ in // user:current
            guard let self = self else { return }

            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustBarrierCost,
                                          categoryValueMap: [ProbeConst.duration: (CACurrentMediaTime() - startTime) * 1000],
                                          context: self.monitorContext)

            self.succCallback()
        }
    }
}

