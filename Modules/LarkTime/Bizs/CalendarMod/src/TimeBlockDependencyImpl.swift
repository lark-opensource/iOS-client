//
//  TimeBlockDependencyImpl.swift
//  CalendarMod-CalendarModAuto
//
//  Created by JackZhao on 2023/11/13.
//

import Calendar
import TodoInterface
import LarkContainer

class TimeBlockDependencyImpl: TimeBlockDependency, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver

    init(userResolver: LarkContainer.UserResolver) {
        self.userResolver = userResolver
    }
    func openTaskPage(from: UIViewController, id: String) {
        let todoBody = TodoDetailBody(guid: id, source: .calendar)
        userResolver.navigator.push(body: todoBody, from: from)
    }
}
