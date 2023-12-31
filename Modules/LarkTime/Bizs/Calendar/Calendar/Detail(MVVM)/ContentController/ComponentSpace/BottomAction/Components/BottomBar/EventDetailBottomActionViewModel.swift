//
//  EventDetailBottomActionViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/26.
//

import RxSwift
import RxRelay
import EventKit
import Foundation
import LarkCombine
import LarkContainer
import LarkRustClient
import CalendarFoundation

final class EventDetailBottomActionViewModel: EventDetailComponentViewModel {

    var model: EventDetailModel { rxModel.value }

    private var isFromVideo: Bool { options.contains(.isFromVideoMeeting) }
    private var rsvpStatusString: String? { payload.rsvpString }
    private var isFromRSVP: Bool { options.contains(.isFromRSVP) }
    private var canJoinEvent: Bool { payload.canJoinIn }

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var localRefresh: LocalRefreshService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ContextObject(\.rxModel) var rxModel
    @ContextObject(\.options) var options
    @ContextObject(\.payload) var payload
    @ContextObject(\.refreshHandle) var refreshHandle
    @ContextObject(\.monitor) var monitor
    @ContextObject(\.scene) var scene

    let viewData = CurrentValueSubject<ReplyViewContent?, Never>(nil)
    let route = PassthroughSubject<Route, Never>()
    let disposeBag = DisposeBag()
    let rxToast = PublishRelay<ToastStatus>()

    override init(context: EventDetailContext, userResolver: UserResolver) {

        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {
        rxModel.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.buildViewData()
        })
        .disposed(by: disposeBag)
    }

    private var isForReview: Bool {
        switch model {
        case .local: return false
        case let .pb(event, _):
            let eventForReview = !(event.calendarID == calendarManager?.primaryCalendarID)
            return options.contains(.needCalculateIsForReview) && eventForReview
        case .meetingRoomLimit: return false
        }
    }
}

// MARK: - Action

extension EventDetailBottomActionViewModel {

    enum Action {
        case changeStatus(status: CalendarEventAttendee.Status)
        case reTap
        case join
        case reply
    }

    enum Route {
        struct ReplyVCParam {
            let status: CalendarEventAttendee.Status
            let inviterCalendarId: String
            let inviterlocalizedName: String
            let calendarId: String
            let key: String
            let originalTime: Int64
            let fromDetail: Bool
            let messageID: String? = nil
            let isWebinar: Bool
            let eventID: String
        }

        struct Option {
            let title: String
            let action: () -> Void
        }

        case url(url: URL)
        case replyVC(param: ReplyVCParam)
        case reTap(options: [Option])
        case replyEventSheet(status: CalendarEventAttendee.Status,
                             spanConfirm: (CalendarEvent.Span) -> Void)
        case unableToJoin(title: String?, message: String?, clickTracer: (() -> Void)?)
    }

    func action(_ action: Action, handle: (() -> Void)? = nil) {
        switch action {
        case .changeStatus(let status): tapStatus(status)
        case .reTap: reTap()
        case .join: tapJoinAction()
        case .reply: tapReplyAction(handle: handle)
        }
    }

    private func reTap() {
        let options: [Route.Option] = [
            .init(title: I18n.Calendar_Detail_Accept) { [weak self] in self?.tapStatus(.accept) },
            .init(title: I18n.Calendar_Detail_Refuse) { [weak self] in self?.tapStatus(.decline) },
            .init(title: I18n.Calendar_Detail_Maybe) { [weak self] in self?.tapStatus(.tentative) }
        ]
        self.route.send(.reTap(options: options))
    }

    func tapJoinAction() {

        EventDetail.logInfo("join action")
        monitor.track(.start(.join))
        guard let event = model.event else { return }

        CalendarTracerV2.EventDetail.traceClick {
            $0.click("join_event")
            $0.event_type = model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: model.instance, event: event))
        }

        rxToast.accept(.loading(info: I18n.Calendar_Share_Joining, disableUserInteraction: false))
        CalendarMonitorUtil.startJoinEventTime(extraName: "event_detail",
                                               calEventID: model.event?.serverID ?? "",
                                               originalTime: model.originalTime,
                                               uid: model.key)
        self.calendarApi?.joinToEvent(calendarID: event.calendarID,
                                     key: event.key,
                                     token: payload.token,
                                     originalTime: event.originalTime,
                                     messageID: payload.messageID)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                self.rxToast.accept(.remove)
                switch data {
                case .event:
                    // 加入日程成功
                    EventDetail.logInfo("join event success")
                    CalendarMonitorUtil.endJoinEventTime(isSuccess: true, errorCode: "")
                    self.monitor.track(.success(.join, self.model, [:]))
                    self.rxToast.accept(.success(I18n.Calendar_Share_JoinSucTip))
                    let reformer = EventDetailShareDataReformer(userResolver: self.userResolver,
                                                                key: self.model.key,
                                                                calendarId: self.model.calendarId,
                                                                originalTime: self.model.originalTime,
                                                                token: self.payload.token,
                                                                messageId: self.payload.messageID,
                                                                actionSource: .refresh, 
                                                                scene: scene)
                    self.refreshHandle.refreshWith(reformer: reformer)
                case .joinFailedData(let filedData):
                    CalendarMonitorUtil.endJoinEventTime(isSuccess: false, errorCode: "")
                    // 超过日程人数管控上限，加入失败
                    EventDetail.logError("join event failed because of reaching to attendee control number")
                    self.monitor.track(.failure(.join, self.model,
                                                RCError.businessFailure(errorInfo: BusinessErrorInfo(
                                                    code: ErrorType.joinEventRichAttendeeNumberLimitErr.rawValue,
                                                    errorStatus: 0,
                                                    errorCode: ErrorType.joinEventRichAttendeeNumberLimitErr.rawValue,
                                                    debugMessage: "",
                                                    displayMessage: "",
                                                    serverMessage: "",
                                                    userErrTitle: "",
                                                    requestID: "")),
                                                [:]))
                    let role = self.calendarManager?.primaryCalendarID == event.organizerCalendarID ? "organizer" : "guest"
                    CalendarTracerV2.EventAttendeeReachLimit.traceView {
                        $0.content = "cannot_join_event"
                        $0.role = role
                        $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
                    }
                    self.route.send(.unableToJoin(title: I18n.Calendar_G_CantJoinEvent_Pop, message: I18n.Calendar_G_CantJoinEvent_Explain(number: filedData.controlMaxAttendeeNum), clickTracer: {
                        CalendarTracerV2.EventAttendeeReachLimit.traceClick {
                            $0.click("confirm").target("none")
                            $0.content = "cannot_join_event"
                            $0.role = role
                            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
                        }
                    }))
                case .none:
                    assertionFailure()
                default:
                    assertionFailure()
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                CalendarMonitorUtil.endJoinEventTime(isSuccess: false, errorCode: "\(error.errorCode())")
                self.monitor.track(.failure(.join, self.model, error, [:]))
                self.rxToast.accept(.remove)
                // 无加入权限弹窗
                let errorType = error.errorType()
                if errorType == .joinEventNoPermissionErr {
                    self.route.send(.unableToJoin(title: nil, message: I18n.Calendar_Share_UnableToJoinEvent, clickTracer: nil))
                } else {
                    self.rxToast.accept(.failure(error.getTitle() ?? I18n.Calendar_Share_JoinFailedTip))
                }
                EventDetail.logError("join event error: \(error)")
            }).disposed(by: self.disposeBag)

        CalendarTracer.shareInstance.calJoinEvent(actionSource: .eventDetail,
                                                  eventType: CalendarTracer.EventType(calendarEventEntity: PBCalendarEventEntity(pb: event)),
                                                  eventId: event.serverID,
                                                  chatId: payload.chatId ?? "",
                                                  isCrossTenant: event.isCrossTenant)
    }

    func tapReplyAction(handle: (() -> Void)?) {

        EventDetail.logInfo("tap reply")
        if let schemaLink = model.event?.dt.schemaLink(key: .rsvpReply) {
            route.send(.url(url: schemaLink))
            return
        }

        guard let event = model.event else { return }
        // RSVP 附言没有重复性弹窗判断，一律按照当前处理
        let originalTime = (model.isRecurrence && model.originalTime == 0) ? model.startTime : event.originalTime

        let receiverUserId = self.getReceiverUserId(successorUserId: event.successor.user.userID,
                                                                 organizerUserId: event.organizer.user.userID,
                                                                 creatorUserId: event.creator.user.userID)
        if let receiverUserId = receiverUserId, let receiverUserId = Int64(receiverUserId) {
            // MARK: 判断能否给组织者发留言
            self.calendarApi?.checkCanRSVPCommentToOragnizer(receiverUserId: receiverUserId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (canSend) in
                    guard let `self` = self else {
                        return
                    }
                    var receiverUserID: String = event.userInviteOperator.userInviteOperatorID
                    var receiverUserName = event.userInviteOperator.userInviteOperatorLocalizedName
                    if canSend {
                        receiverUserID = receiverUserId.description
                        receiverUserName = self.getReceiverUserName(receiverUserId: receiverUserId.description)
                    }
                    self.showReplyVC(receiverUserId: receiverUserID, receiverUserName: receiverUserName)
                    handle?()
                }).disposed(by: disposeBag)
        } else {
            self.showReplyVC(receiverUserId: event.userInviteOperator.userInviteOperatorID, receiverUserName: event.userInviteOperator.userInviteOperatorLocalizedName)
            handle?()
        }
    }

    func showReplyVC(receiverUserId: String, receiverUserName: String) {

        guard let event = model.event else { return }

        let originalTime = (model.isRecurrence && model.originalTime == 0) ? model.startTime : event.originalTime

        let replyParams = Route.ReplyVCParam(status: event.hasSelfAttendeeStatus ? event.selfAttendeeStatus : .needsAction,
                                             inviterCalendarId: receiverUserId,
                                             inviterlocalizedName: receiverUserName,
                                             calendarId: event.calendarID,
                                             key: event.key,
                                             originalTime: originalTime, fromDetail: true,
                                             isWebinar: event.category == .webinar,
                                             eventID: event.serverID)
        route.send(.replyVC(param: replyParams))

        CalendarTracerV2.EventDetail.traceClick {
            $0.click("reply_button").target("none")
            $0.event_type = model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: model.instance, event: model.event))
        }
    }

    /// 获取发送人ID receiverUserId = successor > organizer > creator
    func getReceiverUserId(successorUserId: String?,
                           organizerUserId: String?,
                           creatorUserId: String?) -> String? {

        if let successorUserId = successorUserId, !successorUserId.isEmpty {
            return successorUserId
        }

        if let organizerUserId = organizerUserId, !organizerUserId.isEmpty {
            return organizerUserId
        }

        if let creatorUserId = creatorUserId, !creatorUserId.isEmpty {
            return creatorUserId
        }

        return nil
    }

    func getReceiverUserName(receiverUserId: String?) -> String {
        guard let receiverUserId = receiverUserId, let event = model.event else { return "" }

        if receiverUserId == event.successor.user.userID {
            return event.successor.displayName
        }
        if receiverUserId == event.organizer.user.userID {
            return event.organizer.displayName
        }
        if receiverUserId == event.creator.user.userID {
            return event.creator.displayName
        }
        return ""
    }
}

// MARK: - ViewData
extension EventDetailBottomActionViewModel {

    struct ViewData: ReplyViewContent {
        let ekEvent: EKEvent?
        let showJoinButton: Bool
        let canJoinEvent: Bool
        let isReplyed: Bool
        let showReplyEntrance: Bool
        let rsvpStatusString: String?
        let status: ReplyStatus?
    }

    private func buildViewData() {
        let data = getViewData()
        viewData.send(data)
        EventDetail.logInfo("""
        build viewData.
        showJoinButton: \(data.showJoinButton),
        canJoinEvent: \(data.canJoinEvent),
        isReplyed: \(data.isReplyed),
        showReplyEntrance: \(data.showReplyEntrance),
        status: \(String(describing: data.status))
        """)
    }

    func getViewData() -> ViewData {
        let ekEvent = model.shouldShowLocalActionBar ? model.localEvent : nil
        let showJoinButton = isForReview && !isFromVideo
        let status = model.selfAttendeeStatus
        let isReplyed = isFromRSVP
        var showReplyEntrance = false
        if let event = model.event {
            // 跟 Android 对齐，增加 LocalizedName 判断
            showReplyEntrance = !model.isThirdParty
            && !event.userInviteOperatorID.isEmpty
            && event.userInviteOperatorID != "0"
            && !event.userInviteOperator.userInviteOperatorLocalizedName.isEmpty
            && (event.dt.isSchemaDisplay(key: .rsvp) ?? true)
        }
        return ViewData(ekEvent: ekEvent,
                        showJoinButton: showJoinButton,
                        canJoinEvent: canJoinEvent,
                        isReplyed: isReplyed,
                        showReplyEntrance: showReplyEntrance,
                        rsvpStatusString: rsvpStatusString,
                        status: status)
    }
}
