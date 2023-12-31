//
//  FastLoginTask.swift
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

/// 用于 多 scene 并发启动场景
var isLogining: Bool = false

class FastLoginTask: AsyncBootTask, Identifiable { // user:checked (boottask)
    static var identify = "FastLoginTask"

    @Provider private var launcher: Launcher

    private let disposeBag = DisposeBag()

    override var runOnlyOnceInUserScope: Bool { return false }

    override func execute(_ context: BootContext) {
        if context.currentUserID == nil && !isLogining {
            isLogining = true
            
            // 数据迁移
            if PassportStoreMigrationManager.shared.shouldMigrate() {
                flowCheckout(.passportMigrationFlow)
                return
            }

            // BranchBootTask的checkout需要同步调用
            launcher.fastLogin { [weak self]reuslt in
                isLogining = false
                guard let self = self else { return }
                switch reuslt {
                case .success(let context):

                    if MultiUserActivitySwitch.enableMultipleUser {
                        NewBootManager.shared.didLogin(userID: context.foregroundUser.userID, fastLogin: true)
                    }
                    let bootContext = NewBootManager.shared.context
                    assert(bootContext.isFastLogin, "should set in login delegate")
                    assert(bootContext.currentUserID == context.foregroundUser.userID, "should set in login delegate") // user:current
                    self.end()
                case .failure(_):
                    self.flowCheckout(.launchGuideFlow)
                }
            }
        } else {
            self.end()
        }
    }
}
