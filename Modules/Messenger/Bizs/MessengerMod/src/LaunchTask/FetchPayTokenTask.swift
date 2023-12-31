//
//  FetchPayTokenTask.swift
//  LarkMessenger
//
//  Created by KT on 2020/7/2.
//

import Foundation
import BootManager
import LarkContainer
import LarkMessengerInterface

final class NewFetchPayTokenTask: UserFlowBootTask, Identifiable {
    static var identify = "FetchPayTokenTask"

    @ScopedProvider private var payManagerService: PayManagerService?

    override var scheduler: Scheduler { return .async }

    override func execute(_ context: BootContext) {
        // 8. 拉取财经 Paytoken
        self.payManagerService?.fetchPayTokenIfNeeded()
    }
}
