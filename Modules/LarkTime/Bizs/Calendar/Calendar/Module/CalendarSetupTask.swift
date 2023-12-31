//
//  CalendarSetupTask.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/14.
//
import Foundation
import BootManager
import LarkContainer
import LarkMessageBase
import RxSwift
import LKCommonsLogging

/// BootManager.login
final class CalendarSetupTask: UserFlowBootTask, Identifiable {
    static var identify = "CalendarSetupTask"
    let logger = Logger.log(CalendarSetupTask.self, category: "Calendar.CalendarSetupTask")

    override var scope: Set<BizScope> { return [.calendar] }

    @ScopedInjectedLazy var reminderService: ReminderService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarMyAIService: CalendarMyAIService?

    let disposeBag = DisposeBag()
    override func execute(_ context: BootContext) {
        logger.info("CalendarSetupTask execute.")
        reminderService?.registerObservers()
        calendarMyAIService?.registSelectedExtensionObservers()
        LocalCalendarManager.registerObservers()
        calendarManager?.loadPrimaryCalendarIfNeeded().subscribe().disposed(by: disposeBag)
    }

}
