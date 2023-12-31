//
//  CalendarTodayEventHandler.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/18.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarTodayEventHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarTodayEventBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let todayEventDependency = try userResolver.resolve(assert: TodayEventDependency.self)
        let todayEventService = try userResolver.resolve(assert: TodayEventService.self)
        let dataSource = TodayEventDataSource(userResolver: userResolver)
        let calendarApi = try userResolver.resolve(assert: CalendarRustAPI.self)
        let todayPlanViewModel = TodayPlanViewModel(userResolver: userResolver,
                                                    todayEventDependency: todayEventDependency,
                                                    todayEventService: todayEventService,
                                                    dataSource: dataSource)
        let eventFeedCardViewModel = EventFeedCardViewModel(dataSource: dataSource,
                                                            todayEventDependency: todayEventDependency,
                                                            todayEventService: todayEventService,
                                                            calendarApi: calendarApi,
                                                            userResolver: userResolver,
                                                            feedTab: body.feedTab,
                                                            feedIsTop: body.isTop)
        let vc = TodayEventViewController(dataSource: dataSource,
                                          todayPlanViewModel: todayPlanViewModel,
                                          eventFeedCardViewModel: eventFeedCardViewModel,
                                          userResolver: resolver,
                                          feedTab: body.feedTab,
                                          feedIsTop: body.isTop,
                                          showCalendarID: body.showCalendarID,
                                          feedID: body.feedID)
        res.end(resource: vc)
    }

}
