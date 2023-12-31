//
//  SchedulerAppointmentViewModel.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/29.
//

import Foundation
import LarkContainer
import LarkMessageBase
import LarkModel
import RxSwift
import RustPB
import LarkTimeFormatUtils
import CalendarFoundation
import EENavigator
import LKCommonsLogging

protocol SchedulerAppointmentViewModelContext: ViewModelContext {
    var scene: ContextScene { get }
    var userResolver: UserResolver { get }
}

final class SchedulerAppointmentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: SchedulerAppointmentViewModelContext>: MessageSubViewModel<M, D, C> {

    let logger = Logger.log(SchedulerAppointmentViewModel.self, category: "Calendar.SchedulerCard.Appointment")

    var calendarDependency: CalendarDependency? {
        do {
            return try context.userResolver.resolve(assert: CalendarDependency.self)
        } catch {
            logger.error("can not get dependency from larkcontainer")
            return nil
        }
    }

    override var identifier: String {
        return "SchedulerAppointment"
    }

    override var contentConfig: ContentConfig? {
        var config = ContentConfig(hasMargin: false,
                                   backgroundStyle: .white,
                                   maskToBounds: true,
                                   supportMutiSelect: true,
                                   hasBorder: true)
        config.isCard = true
        return config
    }

    var messageId: String {
        return message.id
    }

    var content: SchedulerAppointmentCardContent {
        return (message.content as? SchedulerAppointmentCardContent)!
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 370)
    }
}


extension SchedulerAppointmentViewModel {
    func onInviteeEmailClick(emailAddr: String?) {
        if let link = emailAddr {
            openURL(link: link)
        }
    }

    func viewDetailAction(detailLink: String?) {
        if let link = detailLink {
            openURL(link: link)
        }
    }

    func openChatter(userID: String?) {
        if let id = userID, let vc = context.targetVC {
            self.calendarDependency?.jumpToProfile(chatterId: id, eventTitle: "", from: vc)
        }
    }

    private func openURL(link: String) {
        if let url = URL(string: link), let vc = context.targetVC {
            self.context.userResolver.navigator.open(url, from: vc)
        }
    }

    func amIHost(hostID: String) -> Bool {
        return calendarDependency?.currentUser.id == hostID
    }
}

extension SchedulerAppointmentViewModel {
    var is12HourStyle: Bool {
        calendarDependency?.is12HourStyle.value ?? true
    }

    func formatTime(startTime: Int64, endTime: Int64, timeZone: TimeZone = TimeZone.current) -> String {
        let customOptions = Options(timeZone: timeZone,
                                    is12HourStyle: is12HourStyle,
                                    timePrecisionType: .minute,
                                    datePrecisionType: .day,
                                    dateStatusType: .absolute,
                                    shouldRemoveTrailingZeros: false)

        return CalendarTimeFormatter.formatFullDateTimeRange(startFrom: getDateFromInt64(startTime),
                                                             endAt: getDateFromInt64(endTime),
                                                             isAllDayEvent: false,
                                                             with: customOptions)
    }
}
