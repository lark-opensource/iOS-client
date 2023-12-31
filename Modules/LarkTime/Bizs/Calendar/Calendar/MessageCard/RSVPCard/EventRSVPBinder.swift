//
//  EventRSVPBinder.swift
//  Calendar
//
//  Created by pluto on 2023/1/17.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import LarkUIKit
import RoundedHUD
import RxCocoa
import RustPB
import EventKit
import RichLabel
import AppReciableSDK
import LarkContainer
import UniverseDesignToast
import UniverseDesignActionPanel
import UniverseDesignDialog
import LKCommonsLogging
import ThreadSafeDataStructure
import LarkModel

public typealias RSVPCardDetailControllerGetter = (DetailControllerGetterModel) -> UIViewController

struct EventRSVPCardModelDefault: RSVPCardModel {
    var chatID: String = ""
    var hasReaction: Bool = false
    var messageId: String = ""
    var calendarID: String = ""
    var userOwnChatterId: String = ""
    var organizerCalendarId: Int64 = 0
    var key: String = ""
    var originalTime: Int = 0
    var headerTitle: String = ""
    var summary: String = ""
    var startTime: Int64?
    var endTime: Int64?
    var isAllDay: Bool?
    var rrule: String?
    var isShowConflict: Bool = false
    var isShowRecurrenceConflict: Bool = false
    var conflictTime: Int64 = 0
    var location: String?
    var meetingRoom: String?
    var desc: String = ""
    var needActionAttendeeIDs: [String] = []
    var needActionAttendeeNames: [String : String] = [:]
    var atMeForegroundColor: UIColor = UIColor()
    var atOtherForegroundColor: UIColor = UIColor()
    var atGroupForegroundColor: UIColor = UIColor()
    var isAllUserInGroupReplyed: Bool = false
    var rsvpAllReplyedCountString: String = ""
    var eventTotalAttendeeCount: Int64 = 0
    var needActionCount: Int64 = 0
    var attendeeRsvpInfo: [RustPB.Basic_V1_AttendeeRSVPInfo] = []
    var cardStatus: LarkModel.EventRSVPCardInfo.EventRSVPCardStatus = .normal
    var selfAttendeeRsvpStatus: CalendarEventAttendee.Status = .needsAction
    var isJoined: Bool = false
    var isInValid: Bool = false
    var isCrossTenant: Bool = false
    var isAttendeeOverflow: Bool = false
    var isWebinar: Bool = false
    var isOptional: Bool = false
    var isUpdated: Bool = false
    var relationTag: String?
    var isTimeUpdated: Bool = false
    var isRruleUpdated: Bool = false
    var meetingNotes: RustPB.Basic_V1_MeetingNotesInfo?
    var isLocationUpdated: Bool = false
    var isResourceUpdated: Bool = false
}

public final class EventRSVPBinder: UserResolverWrapper {
    private let logger = Logger.log(EventRSVPBinder.self, category: "calendar.EventRSVPBinder")

    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    
    public let userResolver: UserResolver
    
    init(model: RSVPCardModel,
         currentTenantId: String,
         controllerGetter: @escaping () -> UIViewController,
         detailControllerGetter: @escaping RSVPCardDetailControllerGetter,
         is12HourStyle: BehaviorRelay<Bool>,
         userResolver: UserResolver) {
        self.controllerGetter = controllerGetter
        self.model.value = model
        self.currentTenantId = currentTenantId
        self.detailControllerGetter = detailControllerGetter
        self.is12HourStyle = is12HourStyle
        self.userResolver = userResolver
    }
    
    private let lock = DispatchSemaphore(value: 1)
    private var model: SafeAtomic<RSVPCardModel> = EventRSVPCardModelDefault() + .readWriteLock
    private var controllerGetter: () -> UIViewController
    public let reloadViewPublish = PublishSubject<Void>()
    private let currentTenantId: String
    private let detailControllerGetter: RSVPCardDetailControllerGetter
    private let is12HourStyle: BehaviorRelay<Bool>
    private let disposeBag = DisposeBag()
    private var handelingUrlTap: Bool = false
    private let delay: TimeInterval = 0.5
    public var maxWidth: CGFloat = 0
    private var meetingNotes: RSVPCardMeetingNotesData?
    private lazy var meetingNotesLoader: MeetingNotesLoader = {
        MeetingNotesLoader(userResolver: self.userResolver)
    }()

    public var componentProps: RSVPCardComponentProps {
        let props = RSVPCardComponentProps()
        let modelValue = model.value
        let userIdForAttendee: String = modelValue.selfAttendeeRsvpStatus == .needsAction ? modelValue.userOwnChatterId : ""
        let attendeeInfo = modelValue.attendeeNameGenerator(userID: userIdForAttendee,
                                                       attendeeNames: modelValue.needActionAttendeeNames,
                                                       attendeeIDs: modelValue.needActionAttendeeIDs,
                                                       groupNames: [:],
                                                       foregroundColor: (modelValue.atMeForegroundColor, modelValue.atOtherForegroundColor, modelValue.atGroupForegroundColor),
                                                       maxWidth: maxWidth - 24)

        //for header
        props.headerTitle = modelValue.headerTitle
        props.cardStatus = modelValue.cardStatus
        
        //for time
        props.time = modelValue.getTime(is12HourStyle: is12HourStyle.value)
        props.conflictText = modelValue.getConflictText(is12HourStyle: is12HourStyle.value)
        
        //for repeat
        props.repeatText = modelValue.getRepeatText()
        
        //for location
        props.location = modelValue.location

        //for meeting room
        props.meetingRooms = modelValue.meetingRoom
        
        //for desc
        /// trim 换行和空格，兼容其他两段的多出来的 /n
        props.descString = modelValue.desc.trimmingCharacters(in: .whitespacesAndNewlines)

        //for padding
        props.needBottomPadding = modelValue.hasReaction
        
        // for attendee
        props.attendeeString = attendeeInfo.attributedString
        props.attendeeRangeDict = attendeeInfo.tapableRangeDic
        props.outOfRangeText = getOutOfRangeText()
        props.isAllUserInGroupReplyed = modelValue.isAllUserInGroupReplyed
        props.rsvpAllReplyedCountString = modelValue.rsvpAllReplyedCountString
        props.eventTotalAttendeeCount = modelValue.eventTotalAttendeeCount
        props.needActionCount = modelValue.needActionCount

        //for join event
        props.joinSelector = #selector(joinTapped)
        props.isJoined = modelValue.isJoined
        props.joinTarget = self
        
        //for rsvp
        props.rsvpStatus = modelValue.selfAttendeeRsvpStatus
        props.declinSelector = #selector(declineTapped)
        props.tentativeSelector = #selector(tentativeTapped)
        props.acceptSelector = #selector(acceptTapped)
        props.replyedBtnRetapSelector = #selector(repleyRetapped)
        props.moreReplyeTappedSelector = #selector(moreRepleyTapped)
        props.rsvpTarget = self

        //for reactionRsvp
        props.reactionRsvpList = getReactionRsvpList()

        //for meetingNotes
        parseMeetingNotesURLIfNeeded()
        props.meetingNotes = self.meetingNotes
        props.userOwnChatterId = modelValue.userOwnChatterId
        
        //for action
        props.tapDetail = { [weak self] in
            self?.goDetail()
        }

        props.tapMeetingNotes = { [weak self] in
            self?.enterDoc()
        }
        
        props.showProfile = { [weak self] (id) in
            guard let `self` = self else { return }
            self.handelingUrlTap = true
            self.logger.info("jump to profile")
            self.calendarDependency?.jumpToProfile(chatterId: id,
                                                  eventTitle: "",
                                                  from: self.controllerGetter())
        }
        
        props.didSelectReaction = { [weak self] type in
            guard let `self` = self else { return }
            self.handelingUrlTap = true
            self.didTapReaction(type: type)
        }
        
        props.didTapReactionMore = {[weak self] type in
               guard let self = self else { return }
               self.handelingUrlTap = true
               self.didTapReactionMore(type: type)
        }
        
        #if !LARK_NO_DEBUG
        // Convenient Debug
        props.showDebugInfo = { [weak self] () in
            guard FG.canDebug,
                  let self = self else { return }
            self.showInfo(info: modelValue.debugDescription, in: self.controllerGetter())
        }
        #endif
        
        props.isShowOptional = modelValue.isOptional
        props.isShowExternal = modelValue.isCrossTenant
        props.isInValid = modelValue.isInValid
        props.isUpdated = modelValue.isUpdated
        props.relationTag = modelValue.relationTag
        props.isTimeUpdate = modelValue.isTimeUpdated
        props.isRruleUpdate = modelValue.isRruleUpdated
        props.isAttendeeOverflow = modelValue.isAttendeeOverflow
        props.isLocationUpdated = modelValue.isLocationUpdated
        props.isResourceUpdated = modelValue.isResourceUpdated
        
        logger.info("user own rsvp status: \(modelValue.selfAttendeeRsvpStatus), isLocationUpdated: \(modelValue.isLocationUpdated), isResourceUpdated: \(modelValue.isResourceUpdated)")
        return props
    }

    public func updateModel(_ model: RSVPCardModel) {
        self.model.value = model
    }

    @objc
    private func acceptTapped() {
        self.handelingUrlTap = true
        self.tapAccept()
    }

    @objc
    private func declineTapped() {
        self.handelingUrlTap = true
        self.tapDecline()
    }

    @objc
    private func tentativeTapped() {
        self.handelingUrlTap = true
        self.tapTentative()
    }

    @objc
    private func repleyRetapped() {
        let options: [(title: String, action: () -> Void)] = [
            (I18n.Calendar_Detail_Accept, { [weak self] in self?.tapAccept() }),
            (I18n.Calendar_Detail_Refuse, { [weak self] in self?.tapDecline() }),
            (I18n.Calendar_Detail_Maybe, { [weak self] in self?.tapTentative() })
        ]

        let actionSheet = UDActionSheet(config: .init())
        options.forEach {
            actionSheet.addDefaultItem(text: $0.title, action: $0.action)
        }
        actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel)
        self.controllerGetter().present(actionSheet, animated: true, completion: nil)
    }
    
    @objc
    private func moreRepleyTapped() {
        let options: [(title: String, action: () -> Void)] = [
            (I18n.Calendar_Detail_Refuse, { [weak self] in self?.tapDecline() }),
            (I18n.Calendar_Detail_Maybe, { [weak self] in self?.tapTentative() })
        ]

        let actionSheet = UDActionSheet(config: .init())
        options.forEach {
            actionSheet.addDefaultItem(text: $0.title, action: $0.action)
        }
        actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel)
        self.controllerGetter().present(actionSheet, animated: true, completion: nil)
    }

    private func tapAccept() {
        let modelValue = self.model.value
        changeEventStatus(status: .accept)
        CalendarTracerV2.EventCard.traceClick {
            $0.click("accept").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.is_new_card_type = "true"
            $0.chat_id = modelValue.chatID
            $0.is_support_reaction = "true"
            $0.is_bot = "false"
            $0.calendar_id = modelValue.calendarID
            $0.is_share = "false"
            $0.is_invited = modelValue.isJoined.description
            $0.is_reply_card = modelValue.isJoined.description
            $0.is_updated = (modelValue.isUpdated || modelValue.isTimeUpdated || modelValue.isRruleUpdated).description
        }
    }

    private func tapDecline() {
        let modelValue = self.model.value
        changeEventStatus(status: .decline)
        CalendarTracerV2.EventCard.traceClick {
            $0.click("reject").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.is_new_card_type = "true"
            $0.chat_id = modelValue.chatID
            $0.is_support_reaction = "true"
            $0.is_bot = "false"
            $0.calendar_id = modelValue.calendarID
            $0.is_share = "false"
            $0.is_invited = modelValue.isJoined.description
            $0.is_reply_card = modelValue.isJoined.description
            $0.is_updated = (modelValue.isUpdated || modelValue.isTimeUpdated || modelValue.isRruleUpdated).description
        }
    }

    private func tapTentative() {
        let modelValue = self.model.value
        changeEventStatus(status: .tentative)
        CalendarTracerV2.EventCard.traceClick {
            $0.click("not_determined").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.is_new_card_type = "true"
            $0.chat_id = modelValue.chatID
            $0.is_support_reaction = "true"
            $0.is_bot = "false"
            $0.calendar_id = modelValue.calendarID
            $0.is_share = "false"
            $0.is_invited = modelValue.isJoined.description
            $0.is_reply_card = modelValue.isJoined.description
            $0.is_updated = (modelValue.isUpdated || modelValue.isTimeUpdated || modelValue.isRruleUpdated).description
        }
    }

    private func changeEventStatus(status: CalendarEventAttendee.Status) {
        logger.info("tap to changeEventStatus to \(status)")
        let modelValue = self.model.value
        CalendarMonitorUtil.startTrackRsvpCardTime(calEventId: "", originalTime: Int64(modelValue.originalTime), uid: modelValue.key)
        let calendarId = modelValue.calendarID
        let key = modelValue.key
        let originalTime = modelValue.originalTime
        let messageID = modelValue.messageId

        api?.replyCalendarEventCardRequest(calendarID: calendarId, key: key, originalTime: Int64(originalTime), messageID: messageID, replyStatus: status)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.localRefreshService?.rxEventNeedRefresh.onNext(())
                CalendarMonitorUtil.endTrackRsvpCardTime()
                self.logger.info("replyCalendarEventCardRequest success.")
                self.showSuccess(status: status)
            }, onError: {[weak self] (error) in
                guard let self = self else { return }
                self.logger.error("replyCalendarEventCardRequest failed with\(error)")
                self.showFailure(error: error)
            }, onDisposed: { [weak self] in
                guard let self = self else { return }
                UDToast.removeToast(on: self.controllerGetter().view)
            }
            )
            .disposed(by: self.disposeBag)
    }

    private func showSuccess(status: CalendarEventAttendee.Status) {
        DispatchQueue.main.asyncAfter(deadline: .now() + self.delay, execute: {
            UDToast.showSuccess(with: status.rsvpSelectedToast, on: self.controllerGetter().view)
        })
    }
    
    private func showFailure(error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            UDToast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Detail_ResponseFailed, on: self.controllerGetter().view)
        })
    }
    
    private func getOutOfRangeText() -> NSAttributedString? {
        let totalAttendeeString = "..."
        let colorAttrbute = [NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentDefault,
                             NSAttributedString.Key.font: UIFont.ud.body2]
        let totalAttendeeAttributeString = NSAttributedString(string: totalAttendeeString, attributes: colorAttrbute)

        return totalAttendeeAttributeString
    }

    private func goDetail() {
        let modelValue = self.model.value
        self.logger.info("tap to go detail with isInValid: \(modelValue.isInValid)")
        guard !modelValue.isInValid else {
            return
        }
        if self.handelingUrlTap {
            self.handelingUrlTap = false
            return
        }
        
        CalendarTracerV2.EventCard.traceClick {
            $0.click("check_more_detail").target("cal_event_detail_view")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.is_new_card_type = "true"
            $0.chat_id = modelValue.chatID
            $0.is_support_reaction = "true"
            $0.is_bot = "false"
            $0.calendar_id = modelValue.calendarID
            $0.is_share = "false"
            $0.is_invited = modelValue.isJoined.description
            $0.is_reply_card = modelValue.isJoined.description
            $0.is_updated = (modelValue.isUpdated || modelValue.isTimeUpdated || modelValue.isRruleUpdated).description
        }
        
        let model = DetailControllerGetterModel(scene: .rsvpCard,
                                                key: modelValue.key,
                                                calendarId: "\(modelValue.organizerCalendarId)",
                                                source: "",
                                                originalTime: Int64(modelValue.originalTime),
                                                startTime: modelValue.startTime ?? 0,
                                                endTime: modelValue.endTime ?? 0,
                                                isJoined: modelValue.isJoined,
                                                messageId: modelValue.messageId,
                                                token: nil,
                                                joinEventAction: self.joinClosure())
        let detailController = self.detailControllerGetter(model)

        if Display.pad {
            let nav = LkNavigationController(rootViewController: detailController)
            nav.update(style: .default)
            nav.modalPresentationStyle = .formSheet
            self.controllerGetter().present(nav, animated: true)
        } else {
            self.controllerGetter().navigationController?.pushViewController(detailController, animated: true)
        }
    }

    private func joinClosure() -> JoinEventAction? {
        let bag = DisposeBag()
        return { (success: @escaping () -> Void, failure: ((Error) -> Void)?) -> Void in
            self.join(success: success, failure: failure, disposeBag: bag, is12HourStyle: self.is12HourStyle.value)
        }
    }

    @objc
    private func joinTapped() {
        let modelValue = self.model.value
        self.handelingUrlTap = true
        CalendarTracerV2.EventCard.traceClick {
            $0.click("join_event").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.is_new_card_type = "true"
            $0.chat_id = modelValue.chatID
            $0.is_support_reaction = "true"
            $0.is_bot = "false"
            $0.calendar_id = modelValue.calendarID
            $0.is_share = "false"
            $0.is_invited = modelValue.isJoined.description
            $0.is_reply_card = modelValue.isJoined.description
            $0.is_updated = (modelValue.isUpdated || modelValue.isTimeUpdated || modelValue.isRruleUpdated).description
        }
        self.join(success: { [weak self] () in
            //update
            self?.logger.info("join event success.")
        }, failure: { [weak self] _ in
            self?.logger.error("join event failed.")
        }, disposeBag: disposeBag, is12HourStyle: is12HourStyle.value)
    }

    private func join(success: @escaping () -> Void,
                      failure: ((Error) -> Void)? = nil,
                      disposeBag: DisposeBag, is12HourStyle: Bool) {
        let modelValue = self.model.value
        let content = modelValue
        if content.isJoined { return }

        CalendarMonitorUtil.startJoinEventTime(extraName: "msg_card",
                                               calEventID: "",
                                               originalTime: Int64(content.originalTime),
                                               uid: content.key)
        UDToast.showLoading(with:BundleI18n.Calendar.Calendar_Share_Joining, on: controllerGetter().view)
        api?.joinToEvent(calendarID: "\(content.organizerCalendarId)", key: content.key, token: nil, originalTime: Int64(content.originalTime), messageID: content.messageId)
            .subscribe(onNext: { (data) in
                switch data {
                case .event:
                    DispatchQueue.main.async(execute: {
                        UDToast.removeToast(on: self.controllerGetter().view)
                        UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_Share_JoinSucTip, on: self.controllerGetter().view)
                        success()
                        CalendarMonitorUtil.endJoinEventTime(isSuccess: true, errorCode: "")
                        CalendarTracer.shareInstance.joinFromShare()
                        CalendarTracer.shareInstance
                            .calJoinEvent(
                                actionSource: .cardMessage,
                                eventType: .event,
                                eventId: "",
                                isCrossTenant: modelValue.isCrossTenant,
                                chatId: content.chatID)
                    })
                case .joinFailedData(let failedData):
                    self.logger.error("join event failed with \(failedData)")

                    CalendarMonitorUtil.endJoinEventTime(isSuccess: false, errorCode: "")
                    DispatchQueue.main.async(execute: {
                        let alertVC = UDDialog(config: UDDialogUIConfig())
                        alertVC.setTitle(text: I18n.Calendar_G_CantJoinEvent_Pop)
                        alertVC.setContent(text: I18n.Calendar_G_CantJoinEvent_Explain(number: failedData.controlMaxAttendeeNum))
                        alertVC.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
                        self.controllerGetter().present(alertVC, animated: true, completion: nil)
                        UDToast.removeToast(on: self.controllerGetter().view)
                    })
                case .none:
                    assertionFailure()
                @unknown default: break
                }
            }, onError: { (error) in
                self.logger.error("join event failed with \(error)")

                CalendarMonitorUtil.endJoinEventTime(isSuccess: true, errorCode: "\(String(describing: error.errorCode()))")
                // 无加入权限弹窗
                let errorType = error.errorType()
                if errorType == .joinEventNoPermissionErr {
                    DispatchQueue.main.async(execute: {
                        let alertVC = UDDialog(config: UDDialogUIConfig())
                        alertVC.setContent(text: I18n.Calendar_Share_UnableToJoinEvent)
                        alertVC.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
                        self.controllerGetter().present(alertVC, animated: true, completion: nil)
                        UDToast.removeToast(on: self.controllerGetter().view)
                    })
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        UDToast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Share_JoinFailedTip, on: self.controllerGetter().view)
                        failure?(error)
                    })
                }
            }, onDisposed: { [weak disposeBag] in
                if disposeBag == nil {
                    UDToast.removeToast(on: self.controllerGetter().view)
                }
            }).disposed(by: disposeBag)
    }
    
    private func getReactionRsvpList() -> [RSVPReactionInfo] {
        let modelValue = self.model.value
        var accept: [(String, String)] = []
        var decline: [(String, String)] = []
        var tentative: [(String, String)] = []
        var needsAction: [(String, String)] = []
        
        modelValue.attendeeRsvpInfo.map {
            switch $0.status {
            case .accept:
                accept.append(($0.displayName, "\($0.chatterID)"))
            case .decline:
                decline.append(($0.displayName, "\($0.chatterID)"))
            case .tentative:
                tentative.append(($0.displayName, "\($0.chatterID)"))
            case .needsAction:
                needsAction.append(($0.displayName, "\($0.chatterID)"))
            @unknown default: break
            }
        }
        
        var rsvpReactionInfo: [RSVPReactionInfo] = []
        if !accept.isEmpty {
            rsvpReactionInfo.append(RSVPReactionInfo(type: .accept,
                                                     justShowCount: false,
                                                     userNameAndIds: accept))
        }
        
        if !decline.isEmpty {
            rsvpReactionInfo.append(RSVPReactionInfo(type: .decline,
                                                     justShowCount: false,
                                                     userNameAndIds: decline))
        }
        
        if !tentative.isEmpty {
            rsvpReactionInfo.append(RSVPReactionInfo(type: .tentative,
                                                     justShowCount: false,
                                                     userNameAndIds: tentative))
        }
        
        if !needsAction.isEmpty {
            rsvpReactionInfo.append(RSVPReactionInfo(type: .needsAction,
                                                     justShowCount: false,
                                                     userNameAndIds: needsAction))
        }
        
        return rsvpReactionInfo
    }
    
    // 暂时只作为埋点时机，后续会增加rsvp行为
    private func didTapReaction(type: Int) {
        let modelValue = self.model.value
        var clickType: String = ""
        switch type {
        case 2:
            clickType = "accept_icon"
        case 4:
            clickType = "reject_icon"
        case 3:
            clickType = "not_determined_icon"
        default: break
        }
        self.logger.info("didTapReaction with: \(clickType)")

        CalendarTracerV2.EventCard.traceClick {
            $0.click(clickType).target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.is_new_card_type = "true"
            $0.chat_id = modelValue.chatID
            $0.is_support_reaction = "true"
            $0.is_bot = "false"
            $0.calendar_id = modelValue.calendarID
            $0.is_share = "false"
            $0.is_invited = modelValue.isJoined.description
            $0.is_reply_card = modelValue.isJoined.description
            $0.is_updated = (modelValue.isUpdated || modelValue.isTimeUpdated || modelValue.isRruleUpdated).description
        }
    }
    
    private func didTapReactionMore(type: Int) {
        logger.info("tap reaction more with type: \(type)")
        if !FG.rsvpStyleOpt { return }
        let modelValue = self.model.value
        let vm = ReactionDetailViewModel(rsvpDataSource: modelValue.attendeeRsvpInfo, type: type)
        let vc = ReactionDetailController(viewModel: vm, userResolver: userResolver)

        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        nav.modalPresentationStyle = .overCurrentContext
        nav.modalTransitionStyle = .crossDissolve
        nav.view.backgroundColor = UIColor.clear
        self.controllerGetter().present(nav, animated: false)
    }

    private func enterDoc() {
        let modelValue = self.model.value
        guard !modelValue.isInValid else {
            return
        }
        if self.handelingUrlTap {
            self.handelingUrlTap = false
            return
        }

        let vc: UIViewController = self.controllerGetter()
        guard let urlStr = modelValue.meetingNotes?.docURL,
              let url = URL(string: urlStr) else {
            return
        }
        meetingNotesLoader.showDocComponent(from: vc,
                                            url: url,
                                            delegate: self,
                                            handleShowCompletion: nil)
        CalendarTracerV2.EventCard.traceClick {
            $0.click("meeting_notes").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.is_new_card_type = "true"
            $0.chat_id = modelValue.chatID
            $0.is_support_reaction = "true"
            $0.is_bot = "false"
            $0.calendar_id = modelValue.calendarID
            $0.is_share = "false"
            $0.is_invited = modelValue.isJoined.description
            $0.is_reply_card = modelValue.isJoined.description
            $0.is_updated = (modelValue.isUpdated || modelValue.isTimeUpdated || modelValue.isRruleUpdated).description
        }
    }
}

extension EventRSVPBinder: CalendarDocComponentAPIDelegate {
    public func onInvoke(data: [String: Any]?, callback: CalendarDocComponentInvokeCallBack?){}

    public func getSubScene() -> String {
        "calendar_rsvp"
    }

    private func parseMeetingNotesURLIfNeeded() {
        guard let notes = model.value.meetingNotes,
              model.value.isJoined else {
            /// 没有meetingNotes
            self.meetingNotes = nil
            return
        }
        let newMeetingNotes: RSVPCardMeetingNotesData? = .init(url: notes.docURL)
        if newMeetingNotes != meetingNotes {
            /// 新旧 meetingNotes url 数据不想等
            self.meetingNotes = newMeetingNotes
            self.parseMeetingNotes(notes: notes)
        }
    }

    private func parseMeetingNotes(notes: RustPB.Basic_V1_MeetingNotesInfo) {
        meetingNotesLoader.getNotesInfo(
            with: notes.docToken,
            docType: notes.docType.rawValue,
            needNotesInfoType: [.meta]
        )
        .subscribe(onNext: { [weak self] notesInfo in
            guard let self = self,
                  let notesInfo = notesInfo else {
                /// 文档被删除
                self?.meetingNotes = .init(url: notes.docURL, isDeleted: true)
                self?.reloadViewPublish.onNext(())
                return
            }
            self.meetingNotes = .init(url: notesInfo.url, parsedTitle: notesInfo.title)
            self.reloadViewPublish.onNext(())
        }).disposed(by: disposeBag)
    }

    public func willClose() {
        guard let notes = model.value.meetingNotes else {
            return
        }
        parseMeetingNotes(notes: notes)
    }
}

#if !LARK_NO_DEBUG
extension EventRSVPBinder: ConvenientDebug {}
#endif

