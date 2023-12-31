//
//  CalendarLoadTask.swift
//  Calendar
//
//  Created by zhuheng on 2021/8/25.
//

import Foundation
import BootManager
import LarkContainer
import LarkMessageBase
import RxSwift

/// BootManager.Idle
final class CalendarLoadTask: UserFlowBootTask, Identifiable {
    static var identify = "CalendarLoadTask"

    @ScopedInjectedLazy var calendarManager: CalendarManager?

    override func execute(_ context: BootContext) {
        calendarManager?.active()
    }

}
