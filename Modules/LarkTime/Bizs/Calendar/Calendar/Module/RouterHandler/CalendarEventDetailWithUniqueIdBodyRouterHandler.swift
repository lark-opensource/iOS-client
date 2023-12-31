//
//  CalendarEventDetailWithUniqueIdBodyRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarEventDetailWithUniqueIdBodyRouterHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarEventDetailWithUniqueIdBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        let calendarVC = interface.getEventContentController(with: body.uniqueId,
                                                             startTime: Int64(body.videoStartTimeStamp),
                                                             instance_start_time: Int64(body.videoStartTimeStamp),
                                                             instance_end_time: Int64(body.videoEndTimeStamp),
                                                             original_time: Int64(body.originalTime),
                                                             vchat_meeting_id: body.meetingID,
                                                             key: body.key)
        res.end(resource: calendarVC)
    }

}
