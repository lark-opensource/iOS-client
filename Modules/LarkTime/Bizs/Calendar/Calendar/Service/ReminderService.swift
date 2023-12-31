//
//  ReminderService.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/10.
//

import UIKit
import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import EventKit
import LarkUIKit
import LarkSceneManager
import RxSwift
import RxRelay
import RoundedHUD
import NotificationUserInfo
import EENotification
import EENavigator
import LarkFeatureGating
import LarkPushCard

protocol ReminderService {
    func registerObservers()
}

final class ReminderServiceImpl: ReminderService, UserResolverWrapper {
    static let logger = Logger.log(ReminderServiceImpl.self, category: "Calendar.ReminderSerice")

    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var rustPushService: RustPushService?
    @ScopedInjectedLazy var calendarInterface: CalendarInterface?
    let calendarDependency: CalendarDependency

    private let settingProvider = SettingService.shared()
    private let disposeBag = DisposeBag()

    private var is12HourStyle: BehaviorRelay<Bool> {
        calendarDependency.is12HourStyle
    }

    let userResolver: UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        calendarDependency = try self.userResolver.resolve(assert: CalendarDependency.self)
    }

    func registerObservers() {
        Self.logger.info("ReminderServiceImpl registerObservers called.")
        rustPushService?.rxEventReminder.subscribe(onNext: { [weak self] (eventReminder) in
            guard let self = self, AppConfig.calendarAlarm else { return }
            self.handleServerNotification(reminder: eventReminder, is12HourStyle: self.is12HourStyle.value) { [weak self] (alertModel, disappearTime, event, alarm) in
                guard let self = self else { return }
                if Date() >= disappearTime { return }
                let timeDiff: Int = self.getTimeDiff(by: event)
                self.showCalendarCard(alertModel: alertModel, event: event, startTime: alarm.startTime, endTime: alarm.endTime, timeDiff: timeDiff, minutes: alarm.minutes) { [weak self] _ in
                    self?.onServerNotificationClosed(reminder: eventReminder)
                }
            }
         }).disposed(by: disposeBag)

        rustPushService?.rxReminderCardClosed.bind { [weak self] (eventAlertId) in
            self?.closeRelatedAlarm(by: eventAlertId)
        }.disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.updateUI()
        }).disposed(by: disposeBag)
    }

    private func updateUI() {
        dismissOvertimeAlarms()
    }

    public func closeRelatedAlarm(by eventAlertId: String) {
        DispatchQueue.main.async {
            if let generator = NotificationIdGenerator(from: eventAlertId) {
                let alarmSortString = generator.getIdWithoutMinute()
                let allCards = PushCardCenter.shared.showCards
                for card in allCards where card.id.contains(alarmSortString) {
                    PushCardCenter.shared.remove(with: card.id)
                }
            }
        }
    }

    public func notificationId(by eventId: String, startTime: String, minutes: String? = nil) -> String {
        if let min = minutes {
            return "Calendar_\(eventId)_\(startTime)_\(min)"
        } else {
            return "Calendar_\(eventId)_\(startTime)"
        }
    }

    private func showCalendarCard(alertModel: Cardable,
                                  event: CalendarEventEntity,
                                  startTime: Int64,
                                  endTime: Int64,
                                  timeDiff: Int,
                                  minutes: Int32,
                                  disMissAction: ((Cardable) -> Void)? = nil) {
        let closeAction = CardButtonConfig(title: BundleI18n.Calendar.Calendar_Common_Close,
                                           buttonColorType: .secondary,
                                           action: { (card: Cardable) in
            PushCardCenter.shared.remove(with: card.id)
            CalendarTracerV2.InAppCardNotification.traceClick {
                $0.click_position = CalendarTracer.InAppCardNotificationClick.close.rawValue
                $0.noti_type = "card"
                $0.time = minutes.description
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event.getPBModel()))
            }

            disMissAction?(alertModel)
            CalendarTracerV2.EventNotification.traceClick {
                $0.click("close").target("none")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event.getPBModel()))
            }
        })
        let detailAction = CardButtonConfig(title: BundleI18n.Calendar.Calendar_Edit_ViewDetail,
                                            buttonColorType: .primaryBlue,
                                            action: { [weak self] (card: Cardable) in
            guard let self = self else { return }
            PushCardCenter.shared.remove(with: card.id, changeToStack: true)
            CalendarTracerV2.InAppCardNotification.traceClick {
                $0.click_position = CalendarTracer.InAppCardNotificationClick.detail.rawValue
                $0.noti_type = "card"
                $0.time = minutes.description
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event.getPBModel()))
            }
            self.jumpToEventDetail(with: event, alertModel: alertModel, startTime: startTime, endTime: endTime)

            disMissAction?(alertModel)
            CalendarTracerV2.EventNotification.traceClick {
                $0.click("check_more_detail").target("cal_event_detail_view")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event.getPBModel()))
            }
        })
        let bodyTapHandler: ((LarkPushCard.Cardable) -> Void)? = { [weak self] (card: Cardable) in
            guard let self = self else { return }
            PushCardCenter.shared.remove(with: card.id, changeToStack: true)
            CalendarTracerV2.InAppCardNotification.traceClick {
                $0.click_position = CalendarTracer.InAppCardNotificationClick.card.rawValue
                $0.noti_type = "card"
                $0.time = minutes.description
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event.getPBModel()))
            }
            self.jumpToEventDetail(with: event, alertModel: alertModel, startTime: startTime, endTime: endTime)

            disMissAction?(alertModel)
            CalendarTracerV2.EventNotification.traceClick {
                $0.click("check_more_detail").target("cal_event_detail_view")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event.getPBModel()))
            }
        }

        let dismissHandler: ((LarkPushCard.Cardable) -> Void)? = { _ in
            disMissAction?(alertModel)
        }

        let card = CalendarPushCard(id: alertModel.id,
                                    priority: .normal,
                                    title: alertModel.title,
                                    buttonConfigs: [closeAction, detailAction],
                                    icon: alertModel.icon,
                                    customView: alertModel.customView,
                                    duration: TimeInterval(timeDiff),
                                    bodyTapHandler: bodyTapHandler,
                                    timedDisappearHandler: dismissHandler,
                                    removeHandler: dismissHandler,
                                    extraParams: alertModel.extraParams)
        closeRelatedAlarm(by: alertModel.id)
        DispatchQueue.main.async {
            PushCardCenter.shared.post(card)

            CalendarTracerV2.InAppCardNotification.traceView {
                $0.time = minutes.description
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event.getPBModel()))
            }

            CalendarTracerV2.EventNotification.traceView {
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event.getPBModel()))
            }
        }
    }

    private func handleServerNotification(reminder: Rust.CalendarReminder,
                                                is12HourStyle: Bool,
                                                callBack: @escaping (Cardable, Date, CalendarEventEntity, CalendarAlarmEntity) -> Void
                                                ) {

        let alarm = PBAlarm.getCalendarAlarmEntity(from: reminder)

        api?.getEvent(calendarId: reminder.calendarID,
                     key: reminder.key,
                     originalTime: reminder.originalTime).subscribe(onNext: { [weak self] (event) in
            self?.showGlobalReminder(event: event, alarm: alarm, callBack: callBack, is12HourStyle: is12HourStyle)
        }, onError: { (error) in
            Self.logger.error(error.localizedDescription)
        }).disposed(by: disposeBag)

    }

    private func showGlobalReminder(event: CalendarEventEntity,
                                           alarm: CalendarAlarmEntity,
                                           callBack: @escaping (Cardable, Date, CalendarEventEntity, CalendarAlarmEntity) -> Void,
                                           is12HourStyle: Bool) {
        let summary = event.summary
        let time = Date(timeIntervalSince1970: TimeInterval(alarm.startTime))
        let meetingRooms = event.attendees
            .filter { $0.isResource && $0.status == .accept && !$0.isDisabled }
            .map({ $0.localizedDisplayName })

        let location = event.location.location
        let disappearTime = getDisappearTime(by: event)
        let alarmExtra = CalendarAlarmExtra(disappearTime: disappearTime) as Any
        let isAllday = event.isAllDay
        DispatchQueue.main.async {
            let alertContentView = CalendarAlertView(title: summary, time: time, meetingRooms: meetingRooms, location: location, isAllday: isAllday, is12HourStyle: is12HourStyle)
            let notificationIdGenerator = NotificationIdGenerator(eventId: event.id,
                                                startTime: String(alarm.startTime),
                                                minutes: String(alarm.minutes))
            let card = CalendarPushCard(id: notificationIdGenerator.getId(),
                                        priority: .normal,
                                        title: BundleI18n.Calendar.Calendar_Bot_CalAssistant,
                                        buttonConfigs: [],
                                        icon: UIImage.cd.image(named: "chat_float"),
                                        customView: alertContentView,
                                        extraParams: alarmExtra)
            callBack(card, disappearTime, event, alarm)
        }
    }

    private func jumpToEventDetail(with event: CalendarEventEntity, alertModel: Cardable, startTime: Int64, endTime: Int64) {
        func doPageChange(from: UIViewController, to: UIViewController) {
            // 防止 VC 全屏时遮挡日程详情跳转。无 VC 页面时，调用无副作用
            calendarDependency.floatingOrDismissByteViewWindow()
            let navi = (from as? UINavigationController) ?? from.navigationController
            if let navi = navi, !Display.pad {
                navi.dismiss(animated: true)
                navi.pushViewController(to, animated: true)
            } else {
                let navi = LkNavigationController(rootViewController: to)
                navi.update(style: .default)
                navi.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                userResolver.navigator.present(to, wrap: LkNavigationController.self,
                                         from: WindowTopMostFrom(vc: from),
                                         prepare: { (vc) in
                    vc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                },
                                         animated: true,
                                         completion: nil)
            }
        }

        PushCardCenter.shared.remove(with: alertModel.id)
        guard let detail = getEventDetailController(event,
                                                 startTime: startTime,
                                                 endTime: endTime) else {
                                                    return
        }

        if SceneManager.shared.supportsMultipleScenes {
            SceneManager.shared.active(scene: .mainScene(), from: nil) { mainSceneWindow, _ in
                if let rootViewController = mainSceneWindow?.rootViewController {
                    doPageChange(from: rootViewController, to: detail)
                } else if let cardWindow = PushCardCenter.shared.window {
                    RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_Toast_CalError, on: cardWindow)
                }
            }
        } else {
            guard let rootVC = userResolver.navigator.mainSceneWindow?.rootViewController else {
                assertionFailure("Missing main scene window")
                return
            }
            doPageChange(from: rootVC, to: detail)
        }
    }

    private func getEventDetailController(_ event: CalendarEventEntity,
                                                 startTime: Int64,
                                                 endTime: Int64) -> UIViewController? {
        if event.getDataSource() == .sdk {
            return calendarInterface?
                .getEventContentController(with: event.key,
                                            calendarId: event.calendarId,
                                            originalTime: event.originalTime,
                                            startTime: startTime,
                                            endTime: endTime,
                                            instanceScore: "",
                                            isFromChat: false,
                                            isFromNotification: true,
                                            isFromMail: false,
                                            isFromTransferEvent: false,
                                           isFromInviteEvent: false,
                                           scene: .reminder)
        } else if event.isLocalEvent() {
            guard let ekevent = event.getEKEvent() else { return nil }
            return (calendarInterface as? CalendarContext)?.getLocalDetailController(ekEvent: ekevent)
        }
        return nil
    }

    private func getTimeDiff(by event: CalendarEventEntity) -> Int {
        if event.isAllDay {
            // 全天日程是卡片出现30分钟后消失。
            return Int(30 * 60)
        } else {
            // 非全天日程是日程开始后30分钟消失
            return Int(event.startTime) - Int(Date().timeIntervalSince1970) + 30 * 60
        }
    }

    private func getDisappearTime(by event: CalendarEventEntity) -> Date {
        return Date(timeIntervalSinceNow: TimeInterval(getTimeDiff(by: event)))
    }

    func dismissOvertimeAlarms() {
        DispatchQueue.main.async {
            let cards = PushCardCenter.shared.showCards
            for card in cards where card.extraParams is CalendarAlarmExtra {
                guard let extra = card.extraParams as? CalendarAlarmExtra else {
                    assertionFailure()
                    return
                }
                if extra.disappearTime < Date() {
                    PushCardCenter.shared.remove(with: card.id)
                }
            }
        }
    }

    func onServerNotificationClosed(reminder: Rust.CalendarReminder) {

        let request = api?.closeEventReminderCard(calendarID: reminder.calendarID,
                                                key: reminder.key,
                                                originalTime: reminder.originalTime,
                                                startTime: reminder.startTime,
                                                minutes: reminder.minutes)
        request?.subscribe(onError: { (_) in
        }).disposed(by: disposeBag)
    }

}

struct CalendarAlarmExtra {
    let disappearTime: Date
}

struct NotificationIdGenerator {
    private let seprator: Character = "_"
    private let calIdentifier = "Calendar"
    private var eventId: String
    private var startTime: String
    private var minutes: String

    init?(from str: String) {
        let eventIdComponents = str.split(separator: seprator)
        if eventIdComponents.count == 4 {
            self.eventId = String(eventIdComponents[1])
            self.startTime = String(eventIdComponents[2])
            self.minutes = String(eventIdComponents[3])
        } else {
            return nil
        }
    }

    public init(eventId: String, startTime: String, minutes: String) {
        self.eventId = eventId
        self.startTime = startTime
        self.minutes = minutes
    }

    public func getId() -> String {
        var id = calIdentifier
        id += String(seprator)
        id += eventId
        id += String(seprator)
        id += startTime
        id += String(seprator)
        id += minutes
        return id
    }

    public func getIdWithoutMinute() -> String {
        var id = calIdentifier
        id += String(seprator)
        id += eventId
        id += String(seprator)
        id += startTime
        return id
    }
}
