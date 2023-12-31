//
//  LoadUrgentTask.swift
//  LarkUrgent
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager
import LarkContainer
import LarkMessengerInterface

final class NewLoadUrgentTask: UserFlowBootTask, Identifiable {
    static var identify = "LoadUrgentTask"

    override class var compatibleMode: Bool { Urgent.userScopeCompatibleMode }

    @ScopedInjectedLazy private var urgencyCenter: UrgencyCenter?

    override func execute(_ context: BootContext) {
        urgencyCenter?.loadAll()
    }
}
