//
//  CalendarTab.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/2.
//

import UIKit
import Foundation
import LarkTab
import LarkContainer
import LarkNavigation

final class CalendarTab: TabRepresentable, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var tabView: TabBarView?
    var tab: Tab { .calendar }
    var customView: UIControl? {
        tabView?.control()
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
}
