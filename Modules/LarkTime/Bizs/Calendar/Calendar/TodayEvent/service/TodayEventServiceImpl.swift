//
//  TodayEventServiceImpl.swift
//  Calendar
//
//  Created by chaishenghua on 2023/9/6.
//

import LarkContainer

class TodayEventServiceImpl: TodayEventService, UserResolverWrapper {
    @ScopedInjectedLazy private var calendarDependency: CalendarDependency?

    var userResolver: LarkContainer.UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
    }

    var is12HourStyle: Bool {
        return calendarDependency?.is12HourStyle.value ?? false
    }

    func jumpToDetailPage(detailModel: TodayEventDetailModel, from vc: UIViewController) {
        let body = CalendarEventDetailBody(eventKey: detailModel.key,
                                           calendarId: detailModel.calendarID,
                                           originalTime: detailModel.originalTime,
                                           startTime: detailModel.startTime,
                                           sysEventIdentifier: "",
                                           isFromChat: false,
                                           isFromNotification: false)
        userResolver.navigator.push(body: body, from: vc)
    }
}
