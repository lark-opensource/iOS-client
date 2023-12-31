//
//  EventDetailFunctionHeaderViewModel+VideoMeeting.swift
//  Calendar
//
//  Created by Rico on 2021/4/19.
//

import UIKit
import Foundation
import RxSwift
import AppReciableSDK
import LarkAlertController

extension EventDetailHeaderViewModel {
    func handleChatAction() {

        guard let event = model.event else {
            return
        }

        ReciableTracer.shared.recStartMeeting()

        if chatBtnDisplayType == .shownAttendeeListInvisible {
            rxMessage.accept(.alert(title: I18n.Calendar_Event_UnableCreateGroup, content: I18n.Calendar_Event_UnableCreateNotes, align: .left))
            return
        }

        if let schemaLink = event.dt.schemaLink(key: .meetingChat) {
            rxRoute.accept(.url(url: schemaLink))
            ReciableTracer.shared.recEndMeeting()
            return
        }

        grayTapFilter()
    }

    // 获取灰度状态 （若获取灰度状态失败，则默认不在灰度）
    private func grayTapFilter() {
        guard let eventID = model.event?.serverID else {
            EventDetail.logError("get severID failed")
            self.doTapChat(false)
            return
        }

        rxToast.accept(.loading(info: I18n.Calendar_Common_LoadingCommon, disableUserInteraction: true))
        calendarApi?.authEventsByEventIDs(eventIds: [eventID])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }

                if let isInGray = res.grayedEventMap[eventID] {
                    EventDetail.logInfo("authEventsByEventIDsRequest success: isInGray = \(isInGray)")
                    self.doTapChat(isInGray)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }

                EventDetail.logError("authEventsByEventIDsRequest failed with: \(error)")
                self.doTapChat(false)
            })
            .disposed(by: disposeBag)
    }

    private func doTapChat(_ isInGray: Bool) {
        /// CASE 1: 创建会议群组
        if canUpdateToMeeting {
            tapToCreateMeetingGroup(isInGray: isInGray)
            return
        }

        /// CASE 2:  申请入群 (灰度内 && 开启入群验证 && 用户不在群)
        if isInGray && isChatOpenEntryAuth && !isInMeetingChat {
            tapToApplyMeetingGroup()
            return
        }

        /// CASE 3: 直接加入会议群
        if canEnterChat {
            tapToEnterMeetingGroup(isInGray: isInGray)
            return
        }

        /// CASE 4: 组织者作为非参与者入群
        if canJoinToMeeting {
            tapToEnterMeetingGroupAsAttendee()
            return
        }

        assertionFailure()
        rxToast.accept(.failure(I18n.Calendar_Meeting_LoadFailed))
    }

    private func tapToCreateMeetingGroup(isInGray: Bool) {
        EventDetail.logInfo("tapToCreateMeetingGroup | isInGray: \(isInGray) ")
        // 非灰度 isRecurrence直接置false，即走老文案的逻辑
        let isRecurrence: Bool = isInGray && (self.model.isRecurrence || self.model.isException)
        let title: String = self.configAlertCopyWritingTitle(isRecurrence: isRecurrence)
        let message: String = self.configAlertCopyWritingMessage(isRecurrence: isRecurrence)

        self.rxToast.accept(.remove)
        self.rxMessage.accept(.createMeeting(title: title, message: message, confirm: { [weak self] in
            guard let self = self else { return }
            self.updateMeetingCondition(false)
            self.trackEventChatCreateConfirmClick(isEnterType: false)
        }))

        self.trackEventChatCreateConfirmView(isEnterType: false)
        self.trackEventDetailClick()
        ReciableTracer.shared.recEndMeeting()
        EventDetail.logInfo("canUpdateToMeeting")
        ReciableTracer.shared.recEndMeeting()
    }

    private func tapToEnterMeetingGroup(isInGray: Bool) {
        EventDetail.logInfo("tapToEnterMeetingGroup | isInGray: \(isInGray) ")
        CalendarTracerV2.EventDetail.traceClick {
            $0.click("enter_chat").target("im_chat_main_view")
            $0.event_type = model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }

        if isOriganizer {
            updateMeetingCondition(false)
            return
        }
        self.rxToast.accept(.remove)
        rxToast.accept(.loading(info: I18n.Calendar_Toast_Entering, disableUserInteraction: true))
        loadChatId()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                let chatId = response.meeting.chatID
                if response.joinChatType == .openAuth && isInGray {
                    self.applyMeetingGroupChat(chatId: chatId)
                } else {
                    ReciableTracer.shared.recEndMeeting()

                    if chatId.isEmpty {
                        // 兜底，存在同一个页面生命周期内，会议群被转为普通群了
                        self.updateMeetingCondition(true)
                    } else {
                        self.goMeetingGroupChat(chatId: chatId)
                    }

                    self.rxToast.accept(.remove)
                    EventDetail.logInfo("go meeting group")
                    ReciableTracer.shared.recEndMeeting()
                }
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    ReciableTracer.shared.recTracerError(errorType: ErrorType.Unknown,
                                                         scene: Scene.CalEventDetail,
                                                         event: .enterMeeting,
                                                         userAction: "cal_enter_meeting",
                                                         page: "cal_event_detail",
                                                         errorCode: Int(error.errorCode() ?? 0),
                                                         errorMessage: error.getMessage() ?? "")
                    self.rxToast.accept(.remove)
                    EventDetail.logError("enter group failed with error: \(error)")
                    if error.isGroupMeetingLimitError {
                        // 群人数上限特定逻辑
                        let alertVC = LarkAlertController()
                        alertVC.setContent(text: error.getServerDisplayMessage() ?? "")
                        alertVC.addSecondaryButton(text: I18n.Lark_Group_Cancel)
                        alertVC.addPrimaryButton(text: I18n.Lark_Group_UplimitContactSalesButton(), numberOfLines: 0, dismissCompletion: {
                            if let helpUrl = URL(string: self.helperCenterUrlString) {
                                self.rxRoute.accept(.url(url: helpUrl))
                            }
                        })
                        self.rxMessage.accept(.alertController(alertController: alertVC))
                        EventDetail.logInfo("group meeting limit")
                        return
                    }

                    if let title = error.getTitle(),
                       let message = error.getMessage(),
                       let confirmTitle = error.getConfirmTitle() {
                        self.rxMessage.accept(.confirmAlert(title: title, message: message, confirmTitle: confirmTitle))
                        return
                    } else {
                        self.updateMeetingCondition(true)
                    }
            }, onDisposed: { [weak self] in
                self?.rxToast.accept(.remove)
            }).disposed(by: disposeBag)
    }

    private func tapToEnterMeetingGroupAsAttendee() {
        EventDetail.logInfo("tapToEnterMeetingGroupAsAttendee")
        self.rxToast.accept(.remove)
        self.rxMessage.accept(.joinMeeting(confirm: { [weak self] in
            self?.updateMeetingCondition(false)
            self?.trackEventChatCreateConfirmClick(isEnterType: true)
        }))

        trackEventChatCreateConfirmClick(isEnterType: true)
        ReciableTracer.shared.recEndMeeting()
    }

    private func tapToApplyMeetingGroup() {
        EventDetail.logInfo("tapToApplyMeetingGroup")
        loadChatId()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (response) in
                guard let self = self else { return }
                if response.joinChatType == .success {
                    self.goMeetingGroupChat(chatId: response.meeting.chatID)
                } else {
                    self.applyMeetingGroupChat(chatId: response.meeting.chatID)
                }
                self.rxToast.accept(.remove)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.rxToast.accept(.remove)
                EventDetail.logError("EventDetailHeader get chatId failed: \(error)")
            }, onDisposed: { [weak self] in
                guard let self = self else { return }
                self.rxToast.accept(.remove)
            }).disposed(by: disposeBag)
    }

    // 升级成会议室得接口调用
    private func updateMeetingCondition(_ retryUpdate: Bool) {

        EventDetail.logInfo("update meeting. retryUpdate: \(retryUpdate) ")

        guard let event = model.event else {
            return
        }

        rxToast.accept(.loading(info: I18n.Calendar_Toast_Entering, disableUserInteraction: true))

        monitor.track(.start(.groupmeeting))
        self.calendarApi?.updateToMeeting(calendarID: event.calendarID,
                                         key: event.key,
                                         originalTime: event.originalTime)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] meeting in
                guard let self = self else { return }
                self.rxToast.accept(.remove)
                self.goMeetingGroupChat(chatId: meeting.chatId)
                var event = event
                event.type = .meeting
                self.refreshHandle.refresh(newEvent: event)
                EventDetail.logInfo("go meeting group + refresh")
                self.monitor.track(.success(.groupmeeting, self.model, [:]))
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.rxToast.accept(.remove)
                self.monitor.track(.failure(.groupmeeting, self.model, error, [:]))
                EventDetail.logError("updateToMeeting failed with : \(error)")
                if error.isGroupMeetingLimitError {
                    // 群人数上限特定逻辑
                    let alertVC = LarkAlertController()
                    alertVC.setContent(text: error.getServerDisplayMessage() ?? "")
                    alertVC.addSecondaryButton(text: I18n.Lark_Group_Cancel)
                    alertVC.addPrimaryButton(text: I18n.Lark_Group_UplimitContactSalesButton(), numberOfLines: 0, dismissCompletion: {
                        if let helpUrl = URL(string: self.helperCenterUrlString) {
                            self.rxRoute.accept(.url(url: helpUrl))
                        }
                    })
                    self.rxMessage.accept(.alertController(alertController: alertVC))
                    EventDetail.logInfo("group meeting limit")
                    return
                }

                if let title = error.getTitle(),
                   let message = error.getMessage() {
                    self.rxMessage.accept(.confirmAlert(title: title, message: message, confirmTitle: nil))
                    return
                }

                if retryUpdate {
                    self.rxToast.accept(.failure(I18n.Calendar_Meeting_LoadFailed))
                    return
                }

                self.rxToast.accept(.failure(error.getTitle() ?? I18n.Calendar_Toast_Retry))

            }, onDisposed: { [weak self] in
                self?.rxToast.accept(.remove)
            }).disposed(by: self.disposeBag)
    }

    private func goMeetingGroupChat(chatId: String) {
        var meetingRoomCount = 0
        var thirdPartyAttendeeCount = 0
        var groupCount = 0
        var userCount = 0
        for attendee in model.visibleAttendees {
            if attendee.isThirdParty {
                thirdPartyAttendeeCount += 1
            } else if attendee.isResource {
                meetingRoomCount += 1
            } else if attendee.isGroup {
                groupCount += 1
            } else {
                userCount += 1
            }
        }

        CalendarTracer.shareInstance.calEnterMeeting(actionSource: .eventDetail,
                                                     eventType: model.event?.type == .meeting ? .meeting : .event,
                                                     meetingRoomCount: meetingRoomCount,
                                                     thirdPartyAttendeeCount: thirdPartyAttendeeCount,
                                                     groupCount: groupCount,
                                                     userCount: userCount,
                                                     isCrossTenant: model.event?.isCrossTenant ?? false,
                                                     eventId: model.event?.serverID ?? "none",
                                                     chatId: chatId,
                                                     viewType: .init(mode: CalendarDayViewSwitcher().mode))

        rxRoute.accept(.chat(chatId: chatId, needApply: false))
        EventDetail.logInfo("go group. chatId: \(chatId)")
    }

    ///  申请入群
    private func applyMeetingGroupChat(chatId: String) {
        rxRoute.accept(.chat(chatId: chatId, needApply: true))
        EventDetail.logInfo("apply group. chatId: \(chatId)")
    }

    /// 此接口调用后直接加群
    private func loadChatId() -> Observable<GetMeetingEventResponse> {

        guard let event = model.event else {
            return .empty()
        }

        return calendarApi?.asnycMeetingEventRequest(calendarId: event.calendarID,
                                                     key: event.key,
                                                     originalTime: event.originalTime) ?? .empty()
    }

    private func configAlertCopyWritingTitle(isRecurrence: Bool) -> String {
        let title: String
        if isRecurrence {
            title = isHaveThirdPartyUser ? BundleI18n.Calendar.Calendar_G_CreateGroupYesMeetPop : BundleI18n.Calendar.Calendar_G_CreateGroupYesMeetEmailPop
        } else {
            title = BundleI18n.Calendar.Calendar_Meeting_CreateMeetingAlert
        }
        return title
    }

    private func configAlertCopyWritingMessage(isRecurrence: Bool) -> String {
        var message: String = ""
        if isRecurrence {
            // 重复性日程 && 参与者
            if isSelfInAttendee {
                message = I18n.Calendar_G_JoinGroupVerificationNote
            } else {
                message = I18n.Calendar_G_CreateGroupNoMeetPop
            }
        } else {
            if isSelfInAttendee {
                // 非重复性日程 & 组织者创建群聊 & 有邮件参与人
                if isHaveThirdPartyUser {
                    message = I18n.Calendar_Meeting_MeetingWithEmail
                } else {
                    message = I18n.Calendar_Meeting_AllGuestJoinMeetingAlert
                }
            } else {
                // 非重复性日程 & 非参与者建群聊 & 有邮件参与人
                if isHaveThirdPartyUser {
                    message = I18n.Calendar_Meeting_NotAttendWithEmail
                } else {
                    message = I18n.Calendar_Meeting_CreateMeetingAndAllGuestJoinAlert
                }
            }
        }
            return message
    }
    
    private var helperCenterUrlString: String {
        if let host = self.calendarDependency?.helperCenterHost {
            return "https://\(host)/hc/zh-CN/articles/360034114413".replaceLocaleForHelperCenterUtlString()
        } else {
            return ""
        }
    }
}

extension EventDetailHeaderViewModel {
    var canUpdateToMeeting: Bool {
        guard let event = model.event else {
            return false
        }

        if event.type == .meeting { return false }
        // 不是会议 且 在我的主日历上 且 (有日程的编辑权限 或 是该日程的参与人), 且没有设置隐藏参与人列表
        return isMyCalendar &&
            (isSelfInAttendee || event.isEditable) &&
               event.guestCanSeeOtherGuests
    }

    var canEnterChat: Bool {
        guard let event = model.event else {
            return false
        }
        return event.type == .meeting && isMyCalendar && isSelfInAttendee
    }

    var canJoinToMeeting: Bool {
        guard let event = model.event else {
            return false
        }
        if !(event.type == .meeting) { return false }
        if !isMyCalendar { return false }
        // 是会议 主日历 有编辑权限 且 我不在参与人里面
        return event.isEditable && !isSelfInAttendee
    }

    var isSelfInAttendee: Bool {

        guard let event = model.event else {
            return false
        }
        let inOrganizerCalendar = event.organizerCalendarID == event.calendarID
        let withoutAttendee = event.attendees.isEmpty
        let organizerNotAttend = !event.willOrganizerAttend
        // 除了（在组织者的日历上 且 （日程没有参与人 或 自己不参与日程））的情况，其他都符合，其他逻辑由SDK控制入口来覆盖
        let exception = inOrganizerCalendar && (withoutAttendee || organizerNotAttend)
        return !event.organizerCalendarID.isEmpty && !exception
    }

    var isMyCalendar: Bool {
        guard let event = model.event else {
            return false
        }
        return event.calendarID == self.calendarManager?.primaryCalendarID
    }

    var isHaveThirdPartyUser: Bool {
        guard let event = model.event else {
            return false
        }
        return event.attendees.contains { $0.category == .thirdPartyUser }
    }

    var isOriganizer: Bool {
        guard let event = model.event else {
            return false
        }
        return event.organizerCalendarID == event.calendarID
    }

    var isOriginzerAttend: Bool {
        guard let event = model.event else {
            return false
        }
        return event.willOrganizerAttend
    }
}

// MARK: - Tracker
extension EventDetailHeaderViewModel {

    private func getEventTypeForTracker() -> String {
        if model.isException {
            return "excepted"
        } else if model.isRecurrence {
            return "repeated"
        } else {
            return "normal"
        }
    }

    private func trackEventChatCreateConfirmClick(isEnterType: Bool) {
        CalendarTracerV2.EventChatCreateConfirm.traceClick {
            $0.click("yes").target("im_chat_main_view")
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
            $0.event_type = self.getEventTypeForTracker()
            $0.is_have_mail_parti = self.isHaveThirdPartyUser ? "true" : "false"
            $0.is_organizer = self.isOriganizer ? "true" : "false"
            $0.is_organizer_included = self.isOriginzerAttend ? "true" : "false"
            $0.popup_type = isEnterType ? "enter_chat" : "create_chat"
        }
    }

    private func trackEventChatCreateConfirmView (isEnterType: Bool) {
        CalendarTracerV2.EventChatCreateConfirm.traceView {
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
            $0.event_type = self.getEventTypeForTracker()
            $0.is_have_mail_parti = self.isHaveThirdPartyUser ? "true" : "false"
            $0.is_organizer = self.isOriganizer ? "true" : "false"
            $0.is_organizer_included = self.isOriginzerAttend ? "true" : "false"
            $0.popup_type = isEnterType ? "enter_chat" : "create_chat"
        }
    }

    private func trackEventDetailClick() {
        CalendarTracerV2.EventDetail.traceClick {
            $0.click("create_chat").target("cal_event_chat_create_confirm_view")
            $0.event_type = model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }
    }
}
