//
//  EventDetailNavigationBarViewModel+Share.swift
//  Calendar
//
//  Created by Rico on 2021/4/13.
//

import Foundation
import RxSwift
import RxRelay
import LarkTimeFormatUtils
import CalendarFoundation
import UIKit

extension EventDetailNavigationBarViewModel {
    func handleShareAction() {

        guard let event = model.event,
              event.dt.isThirdParty == false,
              hasShareButton else { return }

        ReciableTracer.shared.recStartTransf()
        CalendarTracerV2.EventDetail.traceClick {
            $0.click("share_event").target("none")
            $0.event_type = model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }

        doShare()

        ReciableTracer.shared.recEndDelTransf()
    }

    private func doShare() {

        func getShareWebContent() -> String {

            guard let event = model.event else {
                return ""
            }
            // 使用设备时区
            let customOptions = Options(
                timeZone: TimeZone.current,
                is12HourStyle: self.is12HourStyle,
                timePrecisionType: .minute,
                datePrecisionType: .day,
                dateStatusType: .absolute,
                shouldRemoveTrailingZeros: false
            )

            return CalendarTimeFormatter.formatFullDateTimeRange(
                startFrom: event.dt.startDate(with: model.startTime),
                endAt: event.dt.endDate(with: model.endTime),
                isAllDayEvent: event.isAllDay,
                with: customOptions
            )
        }

        guard let event = model.event else {
            return
        }

        if let schema = event.dt.schemaLink(key: .share) {
            rxRoute.accept(.url(url: schema))
            return
        }

        let shareDataObserverGetter = { [weak self] (needImg: Bool) -> Observable<ShareDataModel> in
            guard let self = self, let api = self.calendarApi else { return .just(ShareDataModel(pb: GetEventShareLinkResponse())) }
            return api.getShareLink(calendarId: event.calendarID,
                                    key: event.key,
                                    originTime: event.originalTime,
                                    needImg: needImg)
        }

        sharePanel = EventDetailShareCoordinator(
            userResolver: self.userResolver,
            shareTitle: model.displayTitle,
            shareDataObserverGetter: shareDataObserverGetter,
            shareWebContent: getShareWebContent(),
            onShareTracer: { [weak self] (type) in
                self?.doShareTracer(type: type)
            }, shareToChat: {  [weak self] in
                self?.onlyShareToChat()
            })
        ReciableTracer.shared.recEndDelTransf()
        CalendarTracerV2.EventShare.traceView {
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }
        if let sharePanel = sharePanel {
            rxRoute.accept(.sharePanel(viewController: sharePanel))
            EventDetail.logInfo("show share panel")
        }
    }

    func onlyShareToChat() {

        guard let event = model.event, let tenantID = currentUserInfo?.tenantId else {
            return
        }

        self.share(event: event,
                   currentTenantId: tenantID,
                   refresh: {})
    }

    func share(event: EventDetail.Event,
               currentTenantId: String,
               refresh: @escaping () -> Void
    ) {

        /// 判断可否添加外部参与人/将日程分享给外部参与人
        ///
        /// - Parameters:
        ///   - isMeeting: 此日程是否是会议
        ///   - isCrossTenant: 此日程是否是外部日程
        ///   - hasMeetingMinutes: 此日程是否包含会议纪要
        ///   - isBusinessTenant: 当前用户是否是b端租户
        /// - Returns: 将日程分享给外部人/允许添加外部人
        func canShareToExternal(isMeeting: Bool,
                                isCrossTenant: Bool,
                                hasMeetingMinutes: Bool,
                                isBusinessTenant: Bool) -> Bool {
            //在 外部群/日程 添加成员时，支持搜索添加外部成员
            if isCrossTenant {
                return true
            }
            //会议群聊添加外部人的限制
            let groupChatCondition = !isMeeting
            let meetingMinutesCondition = !hasMeetingMinutes
            return groupChatCondition && meetingMinutesCondition
        }

        operationLog(optType: CalendarOperationType.share.rawValue)
        let tenant = Tenant(currentTenantId: currentTenantId)
        let canAddExternalUser = canShareToExternal(isMeeting: event.type == .meeting,
                                                    isCrossTenant: event.isCrossTenant,
                                                    hasMeetingMinutes: !event.meetingMinuteURL.isEmpty,
                                                    isBusinessTenant: !tenant.isCustomerTenant())

        let shouldShowHint = tenant.isCurrentTenant(isCrossTenant: event.isCrossTenant)
        let pickerCallBack = { [weak self] (chatIds: [String], input: String?, error: Error?, _: Bool) -> Void in
            guard let self = self else { return }
            if error != nil {
                self.rxToast.accept(.failure(I18n.Calendar_Common_FailedToLoad))
                return
            }
            var userCnt = 0
            var groupCnt = 0
            var trdPartyAttendeeCnt = 0
            var meetingRoomCnt = 0
            for attendee in self.model.visibleAttendees {
                if attendee.isThirdParty {
                    trdPartyAttendeeCnt += 1
                } else if attendee.isResource {
                    meetingRoomCnt += 1
                } else if attendee.isGroup {
                    groupCnt += 1
                } else {
                    userCnt += 1
                }
            }
            let isCrossTenant = (self.model.event?.isCrossTenant ?? false) ? "yes" : "no"
            var type: CalendarTracer.EventType = .event
            if event.type == .meeting {
                type = .meeting
            }
            if event.source == .google {
                type = .googleEvent
            }
            if event.source == .exchange {
                type = .exchangeEvent
            }
            if event.source == .email {
                type = .email
            }
            CalendarTracer.shareInstance.calShareEvent(eventType: type,
                                                       meetingRoomCount: meetingRoomCnt,
                                                       thirdPartyAttendeeCount: trdPartyAttendeeCnt,
                                                       groupCount: groupCnt,
                                                       userCount: userCnt,
                                                       eventId: event.serverID,
                                                       chatId: chatIds.first ?? "",
                                                       isCrossTenant: isCrossTenant)
            CalendarTracerV2.EventShare.traceClick {
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
                $0.click("share_to_chat_confirm").target(.none)
                $0.chat_nums = chatIds.count
                if let replyMsg = input?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !replyMsg.isEmpty {
                    $0.message = "true"
                } else {
                    $0.message = "false"
                }
            }

            self.shareEvent(key: event.key,
                            calendarID: event.calendarID,
                            originalTime: event.originalTime,
                            chatIds: chatIds,
                            input: input,
                            disposeBag: self.disposeBag,
                            refresh: refresh)
        }

        let time = getTimeString(startDateTS: event.startTime,
                                 endDateTS: event.endTime,
                                 isAllDayEvent: event.isAllDay,
                                 isInOneLine: true,
                                 is12HourStyle: is12HourStyle)
        rxRoute.accept(.shareForward(eventTitle: model.displayTitle,
                                     duringTime: time,
                                     shareIconName: "event_share_window_icon",
                                     canAddExternalUser: canAddExternalUser,
                                     shouldShowHint: shouldShowHint,
                                     pickerCallBack: pickerCallBack))
        EventDetail.logInfo("share forward")

    }

    func shareEvent(key: String,
                    calendarID: String,
                    originalTime: Int64,
                    chatIds: [String],
                    input: String?,
                    disposeBag: DisposeBag,
                    refresh: @escaping () -> Void) {
        monitor.track(.start(.share))
        self.rxToast.accept(.loading(info: I18n.Calendar_Share_Sharing, disableUserInteraction: true))
        calendarApi?.share(to: chatIds,
                           eventKey: key,
                           originalTime: originalTime,
                           calendarId: calendarID)
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    let faildChats = res.shareFailedChats.map { (result) -> (faildChatName: String, errorCode: Int32) in
                        return (result.chatName, result.errorCode)
                    }.filter({ !$0.faildChatName.isEmpty })
                    if !faildChats.isEmpty {
                        self.rxToast.accept(.remove)
                        let chatNamesByCipherDeleted = faildChats.filter({ ErrorType(rawValue: $0.errorCode) == .invalidCipherFailedToSendMessage })
                        let chatNamesByBanned = faildChats.filter({ ErrorType(rawValue: $0.errorCode) == .forbidSendMessageInChat })
                        var failReasons: [String] = []
                        if !chatNamesByCipherDeleted.isEmpty {
                            let groupNames = chatNamesByCipherDeleted.map({ $0.faildChatName }).joined(separator: I18n.Calendar_Common_DivideSymbol)
                            failReasons.append(I18n.Calendar_KeyDeletedToast_CannotShare_Text(EventName: groupNames))
                            EventDetail.logWarn("share cipher_deleted: \(groupNames)")
                        }
                        if !chatNamesByBanned.isEmpty {
                            let groupNames = chatNamesByBanned.map({ $0.faildChatName }).joined(separator: I18n.Calendar_Common_DivideSymbol)
                            failReasons.append(I18n.Calendar_Share_RestrictionContent(group_name: groupNames))
                            EventDetail.logWarn("share banned: \(groupNames)")
                        }
                        if !failReasons.isEmpty {
                            self.rxRoute.accept(.larkAlertController(title: I18n.Calendar_Share_RestrictionTitle, message: failReasons.joined(separator: "\n")))
                        }
                    }
                    // 发送留言
                    let messageIds = Array(res.chatID2MessageIds.values) + res.message2Threads.values.map(\.threadID)
                    if let replyMsg = input?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !replyMsg.isEmpty,
                       !messageIds.isEmpty {
                        self.calendarDependency?.replyMessages(byIds: messageIds, with: replyMsg)
                    }
                    EventDetail.logInfo("share success")
                    self.monitor.track(.success(.share, self.model, [:]))
                    self.rxToast.accept(.success(I18n.Calendar_Share_SucTip))
                    SlaMonitor.traceSuccess(.ShareEventDetail, action: "share_to_chat", additionalParam: ["need_image": 0])
                    refresh()
                    return

                })
            }, onError: { [weak self] (error) in
                if let self = self {
                    EventDetail.logError("share error: \(error)")
                    self.monitor.track(.failure(.share, self.model, error, [:]))
                    self.rxToast.accept(.failure(error.getTitle(errorScene: .eventShare) ?? BundleI18n.Calendar.Calendar_Share_FaildTip))
                    SlaMonitor.traceFailure(.ShareEventDetail, error: error, action: "share_to_chat", additionalParam: ["need_image": 0])
                }
            }).disposed(by: disposeBag)
    }

    private func doShareTracer(type: CalendarTracer.ShareType) {
        guard let event = model.event else {
            return
        }
        var userCnt = 0
        var groupCnt = 0
        var trdPartyAttendeeCnt = 0
        var meetingRoomCnt = 0
        for attendee in model.visibleAttendees {
            if attendee.isThirdParty {
                trdPartyAttendeeCnt += 1
            } else if attendee.isResource {
                meetingRoomCnt += 1
            } else if attendee.isGroup {
                groupCnt += 1
            } else {
                userCnt += 1
            }
        }

        let isCrossTenant = event.isCrossTenant ? "yes" : "no"
        var eventType: CalendarTracer.EventType = .event
        if event.type == .meeting {
            eventType = .meeting
        }
        if event.source == .google {
            eventType = .googleEvent
        }
        if event.source == .exchange {
            eventType = .exchangeEvent
        }
        if event.source == .email {
            eventType = .email
        }
        CalendarTracer.shareInstance.calShareEvent(eventType: eventType,
                                                   meetingRoomCount: meetingRoomCnt,
                                                   thirdPartyAttendeeCount: trdPartyAttendeeCnt,
                                                   groupCount: groupCnt,
                                                   userCount: userCnt,
                                                   eventId: event.serverID,
                                                   chatId: payload.chatId ?? "",
                                                   isCrossTenant: isCrossTenant,
                                                   type: type)
        let clickMap: [CalendarTracer.ShareType: String] = [
            .chat: "share_to_chat",
            .link: "event_link_copy",
            .screenshot: "event_qr_code"
        ]
        if let click = clickMap[type] {
            CalendarTracerV2.EventShare.traceClick {
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
                $0.click(click).target("cal_event_share_view")
            }
        }
    }
}
