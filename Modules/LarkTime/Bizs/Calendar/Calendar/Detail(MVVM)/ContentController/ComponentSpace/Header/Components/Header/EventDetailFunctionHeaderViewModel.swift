//
//  EventDetailFunctionHeaderViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/3/19.
//

import UIKit
import Foundation
import RxSwift
import LarkCombine
import RxRelay
import LarkContainer
import LarkUIKit
import LarkAlertController
import AppReciableSDK
import UniverseDesignColor

final class EventDetailHeaderViewModel: EventDetailComponentViewModel {

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    
    @ContextObject(\.rxModel) var rxModel
    @ContextObject(\.options) var options
    @ContextObject(\.refreshHandle) var refreshHandle
    @ContextObject(\.monitor) var monitor

    let disposeBag = DisposeBag()
    let rxViewData = BehaviorRelay<EventDetailHeaderViewDataType?>(value: nil)
    let rxRoute = PublishRelay<Route>()
    let rxMessage = PublishRelay<Message>()
    let rxToast = PublishRelay<ToastStatus>()
    // 有效会议FG：影响老纪要的展示
    private var inNotesFg: FGStatus = .pulling

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)
        bindRx()
    }

    var model: EventDetailModel {
        rxModel.value
    }

    private func bindRx() {
        rxModel
            .subscribeForUI(onNext: { [weak self] _ in
                self?.getEventInMeetingNotesFG()
                self?.buildViewData()
            })
            .disposed(by: disposeBag)
    }

    private func buildViewData() {
        let viewData = ViewData(titleColor: model.auroraColor.textColor,
                                markerColor: model.auroraColor.markerColor,
                                buttonTextColor: model.auroraColor.buttonTextColor,
                                buttonBackgroundColor: model.auroraColor.buttonBackgroundColor,
                                relationTagColor: model.auroraColor.relationTagColor,
                                relationTagStr: relationTagStr,
                                title: title,
                                startTime: time.startTime,
                                endTime: time.endTime,
                                isAllDay: time.isAllDay,
                                rruleText: time.subTitle,
                                isShowChat: isShowChat,
                                isShowDocs: isShowDocs,
                                is12HourStyle: is12HourStyle,
                                chatBtnDisplayType: chatBtnDisplayType,
                                docsBtnDisplayType: docsBtnDisplayType,
                                isChatExist: isChatExist,
                                isDocsExist: isDocsExist,
                                webinarTag: webinarTag)
        rxViewData.accept(viewData)
    }

}

extension EventDetailHeaderViewModel {

    struct DetailTimeCellModel {
        var startTime: Date
        var endTime: Date
        var isAllDay: Bool
        var subTitle: String?
    }

    private var title: String {
        return model.displayTitle
    }

    private var time: DetailTimeCellModel {
        let startTime = getDateFromInt64(model.startTime)
        let endTime = getDateFromInt64(model.endTime)
        let isAllDay = model.isAllDay

        var subTitle: String?
        let fullDisplayType = model.displayType == .full
        let onMyPrimaryCalendar = model.event?.dt.isOnMyPrimaryCalendar(calendarManager?.primaryCalendarID) ?? false

        if fullDisplayType || onMyPrimaryCalendar {
            subTitle = model.readableRrule
        }

        if model.displayType == .undecryptable {
            subTitle = nil
        }

        if let schemaDisplay = model.event?.dt.isSchemaDisplay(key: .rrule), !schemaDisplay {
            subTitle = nil
        }

        return DetailTimeCellModel(
            startTime: startTime,
            endTime: endTime,
            isAllDay: isAllDay,
            subTitle: subTitle)
    }

    var isShowChat: Bool {

        return chatBtnDisplayType == .shown || chatBtnDisplayType == .shownAttendeeListInvisible || chatBtnDisplayType == .shownChatOpenEntryAuth
    }

    private var isShowDocs: Bool {
        return docsBtnDisplayType == .shown || docsBtnDisplayType == .shownAttendeeListInvisible
    }

    private var isDocsExist: Bool {
        guard let event = model.event else {
            return false
        }

        return !event.meetingMinuteURL.isEmpty
    }

    private var isChatExist: Bool {
        guard let event = model.event else {
            return false
        }

        let isShowChat = event.type == .meeting && isSelfInAttendee && isMyCalendar
        return isShowChat || canJoinToMeeting
    }

    var chatBtnDisplayType: Rust.EventButtonDisplayType {
        if !AppConfig.detailChat {
            return .hidden
        }

        guard let event = model.event else {
            return .hidden
        }

        if options.contains(.isFromChat) {
            return .hidden
        }

        if !(event.dt.isSchemaDisplay(key: .meetingChat) ?? true) {
            return .hidden
        }

        let result = event.calendarEventDisplayInfo.meetingChatBtnDisplayType
        return result
    }

    var docsBtnDisplayType: Rust.EventButtonDisplayType {

        if shouldHiddenDoc { return .hidden }
        
        if !AppConfig.detailMinutes {
            return .hidden
        }

        guard let event = model.event else {
            return .hidden
        }

        if !(event.dt.isSchemaDisplay(key: .meetingMinutes) ?? true) {
            return .hidden
        }

        let result = event.calendarEventDisplayInfo.meetingMinutesBtnDisplayType

        return result
    }

    var is12HourStyle: Bool {
        return calendarDependency?.is12HourStyle.value ?? true
    }

    var isChatOpenEntryAuth: Bool {
        guard let event = model.event else {
            return false
        }

        return event.eventMeetingChatExtra.isChatOpenEntryAuth
    }

    var isInMeetingChat: Bool {
        guard let event = model.event else {
            return false
        }

        return event.eventMeetingChatExtra.isInMeetingChat
    }
}

// MARK: - Action
extension EventDetailHeaderViewModel {
    enum Action {
        case meeting
        case doc
    }

    func action(_ action: Action) {
        switch action {
        case .meeting: handleChatAction()
        case .doc: handleDocsAction()
        }
    }

    private func handleDocsAction() {

        EventDetail.logInfo("docs action start")

        guard let event = model.event else {
            return
        }

        if docsBtnDisplayType == .shownAttendeeListInvisible {
            EventDetail.logWarn("unable create group")
            rxMessage.accept(.alert(title: I18n.Calendar_Event_UnableCreateGroup, content: I18n.Calendar_Event_UnableCreateNotes, align: .left))
            return
        }

        ReciableTracer.shared.recStartToDoc()
        if let schemaLink = event.dt.schemaLink(key: .meetingMinutes) {
            rxRoute.accept(.url(url: schemaLink))
            return
        }

        monitor.track(.start(.docs))
        rxToast.accept(.loading(info: BundleI18n.Calendar.Calendar_Common_LoadingCommon, disableUserInteraction: false))
        //每次都重新请求，避免出现会议纪要在远端被删除后进入错误的url的情况
        if let event = self.model.event,
           !event.meetingMinuteURL.isEmpty,
           let url = URL(string: event.meetingMinuteURL) {
            rxToast.accept(.remove)
            let isCrossTenant = event.isCrossTenant
            let sha1Value = DocUtils.encryptDocInfo(event.meetingMinuteURL)
            CalendarTracer.shareInstance.calEditEventDoc(eventType: event.type == .meeting ? .meeting : .event,
                                                         actionSource: .eventDetail,
                                                         eventId: event.serverID,
                                                         fileId: sha1Value,
                                                         isCrossTenant: isCrossTenant,
                                                         editType: event.meetingMinuteURL.isEmpty ? .new : .open)

            CalendarTracerV2.EventDetail.traceClick {
                $0.click("create_meeting_minutes").target("ccm_doc_file_page_view")
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
                $0.file_id = sha1Value
                $0.file_type = CalendarTracerV2.EventDetail.parseFileType(with: event.meetingMinuteURL)
                $0.event_type = model.isWebinar ? "webinar" : "normal"
            }

            if Display.pad {
                self.rxRoute.accept(.urlPresent(url: url, style: .fullScreen))
            } else {
                self.rxRoute.accept(.url(url: url))
            }
            monitor.track(.success(.docs, self.model, [:]))
            ReciableTracer.shared.recEndToDoc()
        } else {
            calendarApi?.getDocsUrl(calendarId: event.calendarID,
                                   key: event.key,
                                   originalTime: event.originalTime)
                .subscribeForUI(onNext: { [weak self] (urlString) in
                    guard let self = self,
                          let url = URL(string: urlString),
                          let event = self.model.event else {
                              ReciableTracer.shared.recTracerError(errorType: ErrorType.Network,
                                                                   scene: Scene.CalEventDetail,
                                                                   event: .enterMinutes,
                                                                   userAction: "cal_enter_minutes",
                                                                   page: "cal_event_detail",
                                                                   errorCode: 0,
                                                                   errorMessage: "" )
                              return
                          }

                    let md5Value = (urlString + "42b91e").md5()
                    let sha1Value = ("08a441" + md5Value).sha1()
                    let isCrossTenant = event.isCrossTenant
                    CalendarTracer.shareInstance.calEditEventDoc(eventType: event.type == .meeting ? .meeting : .event,
                                                                 actionSource: .eventDetail,
                                                                 eventId: event.serverID,
                                                                 fileId: sha1Value,
                                                                 isCrossTenant: isCrossTenant,
                                                                 editType: event.meetingMinuteURL.isEmpty ? .new : .open)
                    self.rxToast.accept(.remove)

                    //如果sdk给的url和后端拉的url不一致，更新状态
                    if urlString != event.meetingMinuteURL {
                        EventDetail.logInfo("update docs url")
                        var updatedEvent = event
                        updatedEvent.meetingMinuteURL = urlString
                        self.refreshHandle.refresh(newEvent: updatedEvent)
                    }
                    CalendarTracerV2.EventDetail.traceClick {
                        $0.click("create_meeting_minutes").target("ccm_doc_file_page_view")
                        $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
                        $0.file_id = sha1Value
                        $0.file_type = CalendarTracerV2.EventDetail.parseFileType(with: urlString)
                        $0.event_type = self.model.isWebinar ? "webinar" : "normal"
                    }
                    if Display.pad {
                        self.rxRoute.accept(.urlPresent(url: url, style: .fullScreen))
                    } else {
                        self.rxRoute.accept(.url(url: url))
                    }
                    self.monitor.track(.success(.docs, self.model, [:]))
                    ReciableTracer.shared.recEndToDoc()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    EventDetail.logError("doc action error: \(error)")
                    if error.errorType() == .upgradeExternalMeetingErr {
                        self.rxToast.accept(.remove)
                        self.showMeetingMinutesRestrictAlert()
                    } else {
                        self.rxToast.accept(.failure(error.getTitle() ?? I18n.Calendar_Manage_UnableCreateTryLater))
                    }
                    ReciableTracer.shared.recTracerError(errorType: ErrorType.Network,
                                                         scene: Scene.CalEventDetail,
                                                         event: .enterMinutes,
                                                         userAction: "cal_enter_minutes",
                                                         page: "cal_event_detail", errorCode: Int(error.errorCode() ?? 0),
                                                         errorMessage: error.getMessage() ?? "" )
                    self.monitor.track(.failure(.docs, self.model, error, [:]))
                }, onDisposed: { [weak self] in
                    self?.rxToast.accept(.remove)
                }).disposed(by: disposeBag)
        }
    }

    private func showMeetingMinutesRestrictAlert() {

        guard let event = model.event else {
            return
        }
        let name: String
        let hasOrganizer = !event.organizer.displayName.isEmpty
        let hasSuccessor = !event.successor.displayName.isEmpty
        let hasCreator = !event.creator.displayName.isEmpty
        if hasSuccessor {
            name = event.successor.displayName
        } else if hasOrganizer {
            name = event.organizer.displayName
        } else if hasCreator {
            name = event.creator.displayName
        } else {
            name = BundleI18n.Calendar.Calendar_Detail_Organizer
        }

        rxMessage.accept(.alert(title: nil, content: BundleI18n.Calendar.Calendar_MeetingMinutes_UnavailableDueToAdminPermissionSettings(name: name), align: nil))
    }
}

// MARK: - Route
extension EventDetailHeaderViewModel {
    enum Route {
        case url(url: URL)
        case urlPresent(url: URL, style: UIModalPresentationStyle)
        case chat(chatId: String, needApply: Bool)
    }

    typealias MessageAction = () -> Void
    // 弹窗类
    enum Message {
        case alert(title: String?, content: String, align: NSTextAlignment?)
        case createMeeting(title: String, message: String, confirm: MessageAction)
        case alertController(alertController: LarkAlertController)
        case confirmAlert(title: String, message: String, confirmTitle: String?)
        case joinMeeting(confirm: MessageAction)
    }
}

extension EventDetailHeaderViewModel {
    struct ViewData: EventDetailHeaderViewDataType {
        var titleColor: UIColor
        var markerColor: UIColor
        var buttonTextColor: UIColor
        var buttonBackgroundColor: UIColor
        var relationTagColor: (UIColor, UIColor)
        var relationTagStr: String?
        var title: String
        var startTime: Date
        var endTime: Date
        var isAllDay: Bool
        var rruleText: String?
        var isShowChat: Bool
        var isShowDocs: Bool
        var is12HourStyle: Bool

        var chatBtnDisplayType: Rust.EventButtonDisplayType
        var docsBtnDisplayType: Rust.EventButtonDisplayType
        var isShowVideo = false

        var isChatExist: Bool
        var isDocsExist: Bool
        var webinarTag: DetailHeaderTextTagConfig?
    }
}

// tag
extension EventDetailHeaderViewModel {
    private var webinarTag: DetailHeaderTextTagConfig? {
        var webinarTag: DetailHeaderTextTagConfig?
        if model.isWebinar {
            webinarTag = DetailHeaderTextTagConfig(showTag: true,
                                                   text: BundleI18n.Calendar.Calendar_G_WebinarTag,
                                                   backgroundColor: self.model.auroraColor.markerColor,
                                                   textColor: UDColor.staticWhite)
        }
        return webinarTag
    }

    private var relationTagStr: String? {
        guard let event = model.event else { return nil }
        if !event.relationTagStr.isEmpty && event.displayType == .full {
            return event.relationTagStr
        }
        return nil
    }
}

extension EventDetailHeaderViewModel {

    enum FGStatus {
        /// 拉取中
        case pulling
        /// 在FG内
        case inFG
        /// 在FG外
        case outSideFG
    }

    private var shouldHiddenDoc: Bool {
        /// FG 拉取过程中 || FG内没有老纪要直接不展示
        return inNotesFg == .pulling || (inNotesFg == .inFG && !isDocsExist)
    }

    /// FG内：
    /// - 存在老纪要，显示老纪要，无任何改动
    /// - 不存在老纪要，隐藏按钮
    /// FG外走原先的逻辑，拉到FG之前先不展示老纪要
    private func getEventInMeetingNotesFG() {
        let fourTuple = CalendarRustAPI.InstanceFourTupleRequest(
            calendarID: model.calendarId,
            key: model.key,
            originalTime: model.originalTime,
            instanceStartTime: model.startTime
        )
        calendarApi?.getInstanceRelatedInfo(fourTuple: fourTuple, needNotesInfoType: [])
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.inNotesFg = res.inNotesFg ? .inFG : .outSideFG
                self.buildViewData()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error.errorType() == .instanceInfoErrorInMeetingNotesFG {
                    self.inNotesFg = .inFG
                } else if error.errorType() == .getNotesInstanceNotFound {
                    self.inNotesFg = .inFG
                } else {
                    self.inNotesFg = .outSideFG
                }
                self.buildViewData()
            }).disposed(by: disposeBag)
    }
}
