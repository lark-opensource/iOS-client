//
//  RoundRobinCardViewModel.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/28.
//

import Foundation
import RxSwift
import RustPB
import LarkUIKit
import LarkContainer
import LarkMessageBase
import LarkModel
import LarkTimeFormatUtils
import CalendarFoundation
import UniverseDesignActionPanel
import UniverseDesignToast
import EENavigator
import LKCommonsLogging

protocol RoundRobinCardViewModelContext: ViewModelContext {
    var scene: ContextScene { get }
    var userResolver: UserResolver { get }
}

final class RoundRobinCardViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: RoundRobinCardViewModelContext>: MessageSubViewModel<M, D, C> {

    let logger = Logger.log(RoundRobinCardViewModel.self, category: "Calendar.SchedulerCard.RoundRobin")

    var calendarApi: CalendarRustAPI? {
        do {
            return try context.userResolver.resolve(assert: CalendarRustAPI.self)
        } catch {
            logger.error("can not get calendarApi from larkcontainer")
            return nil
        }
    }

    var calendarDependency: CalendarDependency? {
        do {
            return try context.userResolver.resolve(assert: CalendarDependency.self)
        } catch {
            logger.error("can not get dependency from larkcontainer")
            return nil
        }
    }

    private var disposeBag = DisposeBag()

    override var identifier: String {
        return "RoundRobinCard"
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

    override func willDisplay() {
        super.willDisplay()
        self.disposeBag = DisposeBag()
    }

    override func didEndDisplay() {
        super.didEndDisplay()
        self.disposeBag = DisposeBag()
    }

    var messageId: String {
        return message.id
    }

    var chatID: String {
        self.metaModel.getChat().id
    }

    var content: RoundRobinCardContent {
        return (message.content as? RoundRobinCardContent)!
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 370)
    }
}

extension RoundRobinCardViewModel {
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

    var myUserID: String {
        context.userResolver.userID
    }

    func amIHost(hostID: String) -> Bool {
        return myUserID == hostID
    }

    func amICreator(creatorID: String) -> Bool {
        return myUserID == creatorID
    }
}

extension RoundRobinCardViewModel {

    func onSubtitleNameClick(userID: String?) {
        openChatter(userID: userID)
    }

    func onHostNameClick(hostID: String?) {
        openChatter(userID: hostID)
    }

    func onInviteeEmailClick(emailAddr: String?) {
        if let email = emailAddr, !email.isEmpty {
            openURL(link: "mailto:\(email)")
        }
    }

    func onChangeHost() {
        guard stillEarly else {
            showToast(text: I18n.Calendar_Scheduling_EventStartedExpiredUnable)
            return
        }
        let params = SchedulerChangeHostParam(schedulerID: content.schedulerID,
                                              appointmentID: content.appointmentID,
                                              creatorID: content.creatorID,
                                              hostID: content.hostID,
                                              startTime: content.startTime,
                                              endTime: content.endTime,
                                              message: content.message,
                                              email: content.guestEmail,
                                              timeZone: content.guestTimeZone,
                                              chatID: self.chatID)
        let selectorVC = SchedulerChangeHostViewController(params: params, userResolver: context.userResolver)
        selectorVC.onConfirmed = onConfirmChangeHost
        let panelConfig = UDActionPanelUIConfig(originY: Display.height - SchedulerChangeHostViewController.controllerHeight,
                                                canBeDragged: false,
                                                backgroundColor: UIColor.ud.bgBody)
        let actionPanel = UDActionPanel(customViewController: selectorVC, config: panelConfig)
        if Display.pad {
            let nav = LkNavigationController(rootViewController: selectorVC)
            nav.modalPresentationStyle = .formSheet
            nav.update(style: .custom(UIColor.ud.bgFloat))
            self.context.targetVC?.present(nav, animated: true, completion: nil)
        } else {
            self.context.targetVC?.present(actionPanel, animated: true)
        }

        traceClick("change_host")
    }

    func onReschedule() {
        guard stillEarly else {
            showToast(text: I18n.Calendar_Scheduling_EventStartedExpiredUnable)
            return
        }
        guard let calendarApi = self.calendarApi else {
            logger.error("getAppointmentToken failed, can not get rustapi from larkcontainer")
            return
        }
        showLoadingToast(show: true)
        calendarApi.getAppointmentToken(appointmentID: content.appointmentID, email: content.guestEmail)
            .subscribeForUI(onNext: {[weak self] resp in
                guard let self = self else { return }
                self.showLoadingToast(show: false)
                self.openURL(link: resp.appointmentLinkReschedule)
            }, onError: { [weak self] _ in
                self?.showLoadingToast(show: false)
            }).disposed(by: disposeBag)

        traceClick("reschedule")
    }

    func onCancelScheduler() {
        guard stillEarly else {
            showToast(text: I18n.Calendar_Scheduling_EventStartedExpiredUnable)
            return
        }
        guard let calendarApi = self.calendarApi else {
            logger.error("getAppointmentToken failed, can not get rustapi from larkcontainer")
            return
        }
        showLoadingToast(show: true)
        calendarApi.getAppointmentToken(appointmentID: content.appointmentID, email: content.guestEmail)
            .subscribeForUI(onNext: {[weak self] resp in
                guard let self = self else { return }
                self.showLoadingToast(show: false)
                self.openURL(link: resp.appointmentLinkCancel)
            }, onError: { [weak self] _ in
                self?.showLoadingToast(show: false)
            }).disposed(by: disposeBag)

        traceClick("cancel")
    }

    private func showLoadingToast(show: Bool) {
        if let baseView = context.targetVC?.view {
            if show {
                UDToast.showLoading(with: I18n.Calendar_Common_LoadingCommon, on: baseView)
            } else {
                UDToast.removeToast(on: baseView)
            }
        }
    }

    private func showToast(text: String) {
        if let baseView = context.targetVC?.view {
            UDToast.showFailure(with: text, on: baseView)
        }
    }

    private func openURL(link: String) {
        if let url = URL(string: link), let vc = context.targetVC {
            context.userResolver.navigator.open(url, from: vc)
        }
    }

    private func openChatter(userID: String?) {
        if let id = userID, let vc = context.targetVC {
            self.calendarDependency?.jumpToProfile(chatterId: id, eventTitle: "", from: vc)
        }
    }

    private func onConfirmChangeHost() {
        traceClick("change_host_confirm")
    }

    private var stillEarly: Bool {
        // 10位的时间戳
        let current = Int64(Date().timeIntervalSince1970)
        return current < content.startTime
    }

    struct SchedulerChangeHostParam: SchedulerChangeHostParamType {
        var schedulerID: String
        var appointmentID: String
        var creatorID: String
        var hostID: String
        var startTime: Int64
        var endTime: Int64
        var message: String
        var email: String
        var timeZone: String
        var chatID: String = ""
    }

    private func traceClick(_ clicked: String) {
        CalendarTracerV2.SchedulerEventCard.traceClick {
            $0.click(clicked)
            $0.appointment_id = DocUtils.encryptDocInfo(content.appointmentID)
            $0.scheduler_id = DocUtils.encryptDocInfo(content.schedulerID)
            $0.scheduler_event_type = "round_robin"
            $0.chat_id = chatID
            $0.is_scheduler_creator = amICreator(creatorID: content.creatorID) ? "true" : "false"
        }
    }
}
