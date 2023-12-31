//
//  EventCardBinder.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/10.
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
import EENavigator
import UniverseDesignActionPanel
import UniverseDesignToast
import ThreadSafeDataStructure
import LKCommonsLogging

enum EventType {
    case transfer, invite
}

typealias EventDetailControllerFromCard = (
    _ key: String,
    _ calendarId: String,
    _ originalTime: Int64,
    _ startTime: Int64?,
    _ endTime: Int64?,
    _ eventType: EventType,
    _ scene: EventDetailScene
    ) -> UIViewController

/// RSVP卡片详情
typealias RSVPDetailControllerFromCard = (
    _ entity: Any,
    _ rsvpStatusString: String?) -> UIViewController

struct EventCardModelDefault: InviteEventCardModel {
    var isCrossTenant: Bool = false
    var descAttributedInfo: (string: NSAttributedString, range: [NSRange: URL])? = nil
    var status: CalendarEventAttendee.Status = .accept
    var hasReaction: Bool = false
    var summary: String = ""
    var time: String = ""
    var rrule: String?
    var attendeeIDs: [String]?
    var attendeeNames: [String: String] = [:]
    var groupIds: [String]?
    var groupNames: [String: String] = [:]
    var meetingRooms: String?
    var meetingRoomsInfo: [(name: String, isDisabled: Bool)] = []
    var location: String?
    var desc: String?
    var needAction: Bool = false
    var showReplyInviterEntry: Bool = false
    var rsvpCommentUserName: String?
    var userInviteOperatorId: String?
    var inviteOperatorLocalizedName: String?
    var calendarID: String?
    var eventId: String?
    var eventServerID: String = ""
    var key: String?
    var originalTime: Int?
    var isAccepted: Bool = false
    var isDeclined: Bool = false
    var isTentatived: Bool = false
    var isShowOptional: Bool = false
    var isShowConflict: Bool = false
    var isShowRecurrenceConflict: Bool = false
    var conflictTime: Int64 = 0
    var messageType: Int?
    var startTime: Int64?
    var endTime: Int64?
    var isAllDay: Bool?
    var senderUserName: String = ""
    var senderUserId: String?
    var attendeeCount: Int = 0
    var messageId: String = ""
    var richText: NSAttributedString?
    var atMeForegroundColor: UIColor = UIColor()
    var atOtherForegroundColor: UIColor = UIColor()
    var atGroupForegroundColor: UIColor = UIColor()
    var showTimeUpdatedFlag: Bool = false
    var showRruleUpdatedFlag: Bool = false
    var showLocationUpdatedFlag: Bool = false
    var showMeetingRoomUpdatedFlag: Bool = false
    var isInvalid: Bool = false
    var chatId: String = ""
    // webinar
    var isWebinar: Bool = false
    var speakerChatterIDs: [String] = []
    var speakerNames: [String: String] = [:]
    var speakerGroupIDs: [String] = []
    var speakerGroupNames: [String: String] = [:]
    var relationTag: String?
    var successorUserId: String?
    var organizerUserId: String?
    var creatorUserId: String?
}

public final class EventCardBinder: UserResolverWrapper {

    let logger = Logger.log(EventCardBinder.self, category: "Calendar.EventCard")
    public let userResolver: UserResolver

    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    private let disposeBag = DisposeBag()
    private let delay: TimeInterval = 0.5
    private var getNormalDetailController: EventDetailControllerFromCard
    private let currentTenantId: String
    private let is12HourStyle: BehaviorRelay<Bool>
    private var model: SafeAtomic<InviteEventCardModel> = EventCardModelDefault() + .readWriteLock
    private let userID: String
    private var handelingUrlTap: Bool = false
    private let controllerGetter: () -> UIViewController
    private weak var replyVC: UIViewController?
    private let throttler = Throttler(delay: 1)
    private var isDeleted: Bool {
        let modelValue = self.model.value
        return isDeleted(senderUserName: modelValue.senderUserName, messageType: modelValue.messageType)
    }

    public let reloadViewPublish = PublishSubject<Void>()
    public var maxWidth: CGFloat = 0

    public var componentProps: EventCardComponentProps {
        let tenant = Tenant(currentTenantId: currentTenantId)
        let props = EventCardComponentProps()
        let modelValue = model.value

        let attendeeInfo = modelValue.getAttendeeInfo(isWebinar: modelValue.isWebinar, userID: userID, maxWidth: maxWidth - 50)
        
        // webinar
        props.isWebinar = modelValue.isWebinar

        // for header
        props.summary = modelValue.summary.isEmpty ?
            BundleI18n.Calendar.Calendar_Common_NoTitle : modelValue.summary
        let (attributeStr, range) = getInviteMessage(messageType: modelValue.messageType, senderUserName: modelValue.senderUserName, isInvalid: modelValue.isInvalid, isDeleted: isDeleted)
        props.inviteAttributeString = attributeStr
        props.inviterRange = range
        props.isShowOptional = modelValue.isShowOptional
        props.isShowExternal = tenant.isExternalTenant(isCrossTenant: modelValue.isCrossTenant)
        props.isDeleted = self.isDeleted
        props.isInvalid = modelValue.isInvalid
        props.inviterOnTapped = { [weak self] in
            guard let self = self else { return }
            if let senderUserId = modelValue.senderUserId {
                self.calendarDependency?.jumpToProfile(chatterId: senderUserId,
                                                      eventTitle: "",
                                                      from: self.controllerGetter())
                CalendarTracerV2.EventCard.traceClick {
                    $0.click("title_profile").target("profile_main_view")
                    $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
                    $0.chat_id = modelValue.chatId
                    $0.is_updated = modelValue.isUpdated().description
                    $0.is_invited = modelValue.isInvited().description
                    $0.is_new_card_type = "false"
                    $0.is_support_reaction = "false"
                    $0.is_bot = "true"
                    $0.is_share = "false"
                    $0.is_reply_card = modelValue.isInvited().description
                }
            }
        }
        props.sendUserName = modelValue.senderUserName
        props.messageType = modelValue.messageType
        props.senderUserId = modelValue.senderUserId

        // for time
        props.time = modelValue.getTime(is12HourStyle: is12HourStyle.value)
        props.conflictText = modelValue.getConflictText(is12HourStyle: is12HourStyle.value)

        // for simple text
        props.meetingRooms = modelValue.meetingRooms
        props.repeatText = modelValue.getRepeatText()
        props.location = modelValue.location

        // for attendee
        props.attendeeString = attendeeInfo.attributedString
        props.attendeeRangeDict = attendeeInfo.tapableRangeDic
        props.outOfRangeText = getOutOfRangeText(attendeeCount: modelValue.attendeeCount)

        // for desc
        props.descString = modelValue.descAttributedInfo?.string
        props.descRangeDict = modelValue.descAttributedInfo?.range

        // for rsvp
        props.rsvpStatus = modelValue.status
        props.declinSelector = #selector(declineTapped)
        props.tentativeSelector = #selector(tentativeTapped)
        props.replySelector = replyTapped
        props.acceptSelector = #selector(acceptTapped)
        props.replyedBtnRetapSelector = #selector(repleyRetapped)
        props.target = self
        props.ableToAction = modelValue.needAction
        props.userInviteOperatorId = modelValue.userInviteOperatorId
        props.successorUserId = modelValue.successorUserId
        props.organizerUserId = modelValue.organizerUserId
        props.creatorUserId = modelValue.creatorUserId
        props.showReplyStasus = self.map(messageType: modelValue.messageType) == .rsvpComment
        props.showRSVPInviterEntry = modelValue.showReplyInviterEntry
        props.rsvpCommentUserName = modelValue.rsvpCommentUserName

        props.replyStasusString = getReplyStasusString(status: modelValue.status, rsvpCommentUser: modelValue.rsvpCommentUserName)
        // for padding
        props.needBottomPadding = modelValue.hasReaction

        // action
        props.tapDetail = { [weak self] () in
            guard let `self` = self else {
                return
            }
            if self.handelingUrlTap {
                self.handelingUrlTap = false
                return
            }
            self.throttler.call { [weak self] in
                guard let `self` = self else {
                    return
                }
                self.tapDetail(model: modelValue)
            }
        }

        #if !LARK_NO_DEBUG
        // Convenient Debug - EventCard
        props.showDebugInfo = { [weak self] () in
            guard FG.canDebug,
                  let self = self else { return }
            self.showInfo(info: modelValue.debugDescription, in: self.controllerGetter())
        }
        #endif

        props.jumpUrl = { [weak self] (url) in
            guard let `self` = self else { return }
            self.handelingUrlTap = true
            self.jumpUrl(url: url)
        }

        props.showProfile = { [weak self] (chatID) in
            guard let `self` = self else { return }
            self.handelingUrlTap = true
            self.calendarDependency?.jumpToProfile(chatterId: chatID,
                                                  eventTitle: self.componentProps.summary ?? "",
                                                  from: self.controllerGetter())
            CalendarTracerV2.EventCard.traceClick {
                $0.click("attendee_profile").target("profile_main_view")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
                $0.chat_id = modelValue.chatId
                $0.is_updated = modelValue.isUpdated().description
                $0.is_invited = modelValue.isInvited().description
                $0.is_new_card_type = "false"
                $0.is_support_reaction = "false"
                $0.is_bot = "true"
                $0.is_share = "false"
                $0.is_reply_card = modelValue.isInvited().description
            }
        }

        props.relationTag = modelValue.relationTag

        var updatedComponents = EventCardUpdatedComponents()
        if modelValue.showTimeUpdatedFlag {
            updatedComponents.insert(.time)
        }
        if modelValue.showRruleUpdatedFlag {
            updatedComponents.insert(.rrule)
        }
        if modelValue.showLocationUpdatedFlag {
            updatedComponents.insert(.location)
        }
        if modelValue.showMeetingRoomUpdatedFlag {
            updatedComponents.insert(.meetingRoom)
        }
        props.updatedComponents = updatedComponents
        
        props.shouldDeleteReply = FeatureGating.shouldDeleteReply(userID: self.userResolver.userID)
        return props
    }
    private func getReplyStasusString(status: CalendarEventAttendee.Status, rsvpCommentUser: String?) -> String? {
        let userName = rsvpCommentUser ?? ""
        switch status {
        case .accept:
            return BundleI18n.Calendar.Calendar_Detail_Acceptedrsvp(name: userName)
        case .tentative:
            return BundleI18n.Calendar.Calendar_Detail_Maybersvp(name: userName)
        case .decline:
            return BundleI18n.Calendar.Calendar_Detail_Rejectrsvp(name: userName)
        @unknown default:
            return nil
        }
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

    private func getReplyController(from: UIViewController,
                                    status: CalendarEventAttendee.Status,
                                    calendarId: String,
                                    inviteUserId: String,
                                    inviteOperatorLocalizedName: String?,
                                    key: String,
                                    originalTime: Int,
                                    messageId: String?) -> UIViewController {
        let modelValue = model.value

        let controller = EventReplyViewController(userResolver: self.userResolver,
                                                  status: status,
                                                  inviterCalendarId: inviteUserId,
                                                  inviterlocalizedName: inviteOperatorLocalizedName,
                                                  calendarId: calendarId,
                                                  key: key,
                                                  originalTime: Int64(originalTime),
                                                  messageId: messageId,
                                                  traceContext: .init(eventID: modelValue.eventServerID,
                                                                      startTime: modelValue.startTime ?? 0,
                                                                      isRecurrence: !modelValue.rrule.isEmpty,
                                                                      originalTime: modelValue.originalTime,
                                                                      uid: modelValue.key),
                                                  isWebinar: modelValue.isWebinar) { [weak self] chatID in
            // Jump to chat
            CalendarTracer.shareInstance.rsvpReplyFromCardMessage()
            guard let `self` = self else { return }
            self.replyVC?.dismiss(animated: true, completion: { [weak self] in
                self?.calendarDependency?.jumpToChatController(from: from,
                                                              chatID: chatID,
                                                              onError: { [weak from] in
                                                                guard let from = from else { return }
                                                                UDToast().showFailure(with: BundleI18n.Calendar.Lark_Legacy_RecallMessage, on: from.view)
                                                              },
                                                              onLeaveMeeting: { () in
                    from.navigationController?.popToRootViewController(animated: true)
                })
            })
        }
        controller.isFromBot = true
        let containerVC = SwipeContainerViewController(subViewController: controller)
        containerVC.originY = 64 + UIApplication.shared.statusBarFrame.size.height / 2
        containerVC.showMiddleState = false
        controller.dismiss = { [weak containerVC] (_) in
            containerVC?.dismiss()
        }

        controller.rsvpChange = { [weak self] (status) in
            self?.model.value.status = status
            self?.reloadViewPublish.onNext(())
        }

        return containerVC

    }

    private func replyTapped() {
        let modelValue = self.model.value
        CalendarTracerV2.EventCard.traceClick {
            $0.click("reply_button")
            $0.is_updated = modelValue.isUpdated().description
            $0.is_invited = modelValue.isInvited().description
            $0.event_type = modelValue.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: model.value))
            $0.is_new_card_type = "false"
            $0.is_support_reaction = "false"
            $0.is_bot = "true"
            $0.is_share = "false"
            $0.is_reply_card = modelValue.isInvited().description
        }
        guard let calendarId = modelValue.calendarID,
            let key = modelValue.key,
            let originalTime = modelValue.originalTime,
            let eventServerID = modelValue.eventId else {
            RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: self.controllerGetter().view)
            return
        }

        var receiverUserId = self.getReceiverUserId(successorUserId: componentProps.successorUserId,
                                                    organizerUserId: componentProps.organizerUserId,
                                                    creatorUserId: componentProps.creatorUserId)

        if let inviteUserId = self.componentProps.userInviteOperatorId {
            if let receiverUserId = receiverUserId, let receiverUserId = Int64(receiverUserId) {
                // MARK: 判断能否给组织者发留言
                self.api?.checkCanRSVPCommentToOragnizer(receiverUserId: receiverUserId)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (canSend) in
                        guard let `self` = self else {
                            return
                        }
                        var receiverUserID: String = inviteUserId
                        receiverUserID = canSend ? receiverUserId.description : inviteUserId
                        self.showReplyVC(receiverUserId: receiverUserID, receiverUserName: nil)
                        self.reloadViewPublish.onNext(())
                    }).disposed(by: disposeBag)
            } else {
                self.showReplyVC(receiverUserId: inviteUserId, receiverUserName: modelValue.inviteOperatorLocalizedName)
                self.reloadViewPublish.onNext(())
            }
            return
        }

        let refidCalendarMap = [eventServerID: calendarId]
        self.api?
            .getEventInviteUserId(serverId: eventServerID, refidCalendarMap: refidCalendarMap, receiverUserId: receiverUserId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteUserId) in
                guard let `self` = self, let inviteUserId = inviteUserId, !inviteUserId.isEmpty else {
                    self?.reloadViewPublish.onNext(())
                    return
                }
                self.showReplyVC(receiverUserId: inviteUserId, receiverUserName: modelValue.inviteOperatorLocalizedName)
                self.reloadViewPublish.onNext(())
            }, onError: { (error) in
                operationLog(message: error.getTitle() ?? BundleI18n.Calendar.Calendar_Common_EventHasBeenDeleteTip)
                self.reloadViewPublish.onNext(())
            }, onCompleted: { [weak self] in
                if let self = self { self.reloadViewPublish.onNext(()) }
            }).disposed(by: disposeBag)

    }

    func showReplyVC(receiverUserId: String, receiverUserName: String?) {

        let modelValue = self.model.value

        guard let calendarId = modelValue.calendarID,
            let key = modelValue.key,
            let originalTime = modelValue.originalTime else {
            RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: self.controllerGetter().view)
            return
        }

        let replyVC = self.getReplyController(
            from: self.controllerGetter(),
            status: modelValue.status,
            calendarId: calendarId,
            inviteUserId: receiverUserId,
            inviteOperatorLocalizedName: receiverUserName,
            key: key,
            originalTime: originalTime,
            messageId: modelValue.messageId)
        self.replyVC = replyVC
        self.controllerGetter().present(replyVC, animated: true, completion: nil)
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

    private let getRsvpDetailController: RSVPDetailControllerFromCard
    init(controllerGetter: @escaping () -> UIViewController,
         getNormalDetailController: @escaping EventDetailControllerFromCard,
         getRsvpDetailController: @escaping RSVPDetailControllerFromCard,
         userID: String,
         currentTenantId: String,
         is12HourStyle: BehaviorRelay<Bool>,
         model: InviteEventCardModel,
         userResolver: UserResolver) {
        self.getRsvpDetailController = getRsvpDetailController

        self.model.value = model
        self.currentTenantId = currentTenantId
        self.is12HourStyle = is12HourStyle
        self.getNormalDetailController = getNormalDetailController
        self.userID = userID
        self.controllerGetter = controllerGetter
        self.userResolver = userResolver
    }

    public func updateModel(_ model: InviteEventCardModel) {
        self.model.value = model
    }

    private func getOutOfRangeText(attendeeCount: Int) -> NSAttributedString? {
        let totalAttendeeString = "..."
        let colorAttrbute = [NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentDefault,
                             NSAttributedString.Key.font: UIFont.body3]
        let totalAttendeeAttributeString = NSAttributedString(string: totalAttendeeString, attributes: colorAttrbute)

        return totalAttendeeAttributeString
    }

    private func isDeleted(senderUserName: String, messageType: Int?) -> Bool {
        if let messageType = messageType {
            return messageType == 5
        } else {
            return senderUserName.contains("取消了日程")
        }
    }

    private func map(messageType: Int?) -> CardType {
        return CardType(rawValue: messageType ?? CardType.unknown.rawValue) ?? .unknown
    }

    private func getInviteMessage(messageType: Int?, senderUserName: String, isInvalid: Bool, isDeleted: Bool) -> (NSAttributedString, NSRange) {
        let titleColor = isDeleted ? UIColor.ud.udtokenMessageCardTextNeutral : UIColor.ud.udtokenMessageCardTextOrange
        let attribues: [NSAttributedString.Key: Any] = [.font: UIFont.ud.body2,
                                                        .foregroundColor: titleColor]
        let modelValue = model.value
        if isInvalid {
            return (NSAttributedString(string: BundleI18n.Calendar.Calendar_Bot_EventInfoUpdated,
                                       attributes: attribues), NSRange(location: 0, length: 0))
        }

        if let messageType = messageType {
            let hasSender = modelValue.senderUserId?.isEmpty ?? false
            let senderUserName = hasSender ? senderUserName : ("@" + senderUserName)
            let title = botTitle(with: senderUserName, messageType: messageType)
            let range = NSString(string: title).range(of: senderUserName)
            return (NSAttributedString(string: title,
                                       attributes: attribues), range)
        } else {
            let oldTitle = oldTitle(senderUserName: senderUserName)
            return (NSAttributedString(string: oldTitle,
                                       attributes: attribues), NSRange(location: 0, length: 0))
        }
    }

    /// 兼容历史版本
    private func oldTitle(senderUserName: String) -> String {
        return senderUserName.replacingOccurrences(of: "邀请你加入日程", with: BundleI18n.Calendar.Calendar_Bot_InvitationNotify)
            .replacingOccurrences(of: "取消了日程", with: BundleI18n.Calendar.Calendar_Bot_InvitationCanceled)
            .replacingOccurrences(of: "更新了日程时间", with: BundleI18n.Calendar.Calendar_Bot_InvitationUpdateTime)
            .replacingOccurrences(of: "更新了日程地点", with: BundleI18n.Calendar.Calendar_Bot_InvitationUpdateLoc)
            .replacingOccurrences(of: "更新了日程描述", with: BundleI18n.Calendar.Calendar_Bot_InvitationUpdateDes)
    }

    private func botTitle(with userName: String, messageType: Int) -> String {
        let modelValue = model.value
        switch map(messageType: messageType) {
        case .replyAccept, .replyDecline, .replyTentative, .eventInvite:
            if modelValue.isWebinar {
                return I18n.Calendar_G_NameInviteYouToWebinar(name: userName)
            } else {
                return I18n.Lark_CalendarCard_NameInviteJoinEvent_Text(name: userName)
            }
        case .eventDelete:
            return I18n.Lark_CalendarCard_NameDeletedEvent_Text(name: userName)
        case .eventReschedule:
            return I18n.Lark_CalendarCard_NameUpdatedEvent_Text(name: userName)
        case .eventUpdateLocation:
            return I18n.Lark_CalendarCard_NameUpdatedEvent_Text(name: userName)
        case .eventUpdateDescription:
            return I18n.Lark_CalendarCard_NameUpdatedEvent_Text(name: userName)
        case .transferEvent:
            return BundleI18n.Calendar.Calendar_Transfer_SuccessTransferBot(name: userName)
        case .rsvpComment:
            return ""
        case .switchCalendar:
            return BundleI18n.Calendar.Calendar_Bot_EventTransferredToNewCalendarTitle(name: userName)
        default:
            assertionFailureLog()
            return ""
        }
    }

    private func jumpUrl(url: URL) {
        self.userResolver.navigator.push(url, context: ["from": "calendar"], from: controllerGetter())
    }

    private func tapAccept() {
        let modelValue = model.value
        CalendarTracerV2.EventCard.traceClick {
            $0.click("accept").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.chat_id = modelValue.chatId
            $0.is_updated = modelValue.isUpdated().description
            $0.is_invited = modelValue.isInvited().description
            $0.event_type = modelValue.isWebinar ? "webinar" : "normal"
            $0.is_new_card_type = "false"
            $0.is_support_reaction = "false"
            $0.is_bot = "true"
            $0.is_share = "false"
            $0.is_reply_card = modelValue.isInvited().description
        }
        changeEventStatus(status: .accept)
    }

    private func tapDecline() {
        let modelValue = model.value
        CalendarTracerV2.EventCard.traceClick {
            $0.click("reject").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.chat_id = modelValue.chatId
            $0.is_updated = modelValue.isUpdated().description
            $0.is_invited = modelValue.isInvited().description
            $0.event_type = modelValue.isWebinar ? "webinar" : "normal"
            $0.is_new_card_type = "false"
            $0.is_support_reaction = "false"
            $0.is_bot = "true"
            $0.is_share = "false"
            $0.is_reply_card = modelValue.isInvited().description
        }
        changeEventStatus(status: .decline)
    }

    private func tapTentative() {
        let modelValue = model.value
        CalendarTracerV2.EventCard.traceClick {
            $0.click("not_determined").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelValue))
            $0.chat_id = modelValue.chatId
            $0.is_updated = modelValue.isUpdated().description
            $0.is_invited = modelValue.isInvited().description
            $0.event_type = modelValue.isWebinar ? "webinar" : "normal"
            $0.is_new_card_type = "false"
            $0.is_support_reaction = "false"
            $0.is_bot = "true"
            $0.is_share = "false"
            $0.is_reply_card = modelValue.isInvited().description
        }
        changeEventStatus(status: .tentative)
    }

    private func tapDetail(model: InviteEventCardModel) {
        guard !self.isDeleted else {
            return
        }
        CalendarTracer.shareInstance.calBotDetail()
        let modelVaule = self.model.value
        CalendarTracerV2.EventCard.traceClick {
            $0.click("check_more_detail").target("cal_event_detail_view")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: modelVaule))
            $0.chat_id = modelVaule.chatId
            $0.is_updated = modelVaule.isUpdated().description
            $0.is_invited = modelVaule.isInvited().description
            $0.event_type = modelVaule.isWebinar ? "webinar" : "normal"
            $0.is_share = "false"
            $0.is_reply_card = modelVaule.isInvited().description
        }
        detailAction(model: model)
    }

    private func jumpToTransferEventDetail(key: String, calendarId: String, originalTime: Int) {
        let detailVC = self.getNormalDetailController(key, calendarId, Int64(originalTime), nil, nil, .transfer, .transferCard)
        api?.isEventOnCurrentCalendar(key: key, calendarId: calendarId, originalTime: Int64(originalTime))
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (result) in
                if result {
                    self?.jumpToDetail(detailVC)
                } else if let view = self?.controllerGetter().view {
                    RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_Transfer_eventNoLongerExist, on: view)
                }
            }, onError: { [weak self] (error) in
                if let view = self?.controllerGetter().view {
                    RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Common_EventHasBeenDeleteTip, on: view)
                }
            }).disposed(by: disposeBag)
    }

    private func jumpToRsvpEventDetail(key: String, calendarId: String, originalTime: Int) {
        guard let api = self.api else {
            logger.error("jumpToRsvpEventDetail failed, can not get rust api from larkcontainer")
            return
        }
        var observable = api.isRSVPCardRemoved(calendarID: calendarId, key: key, originalTime: Int64(originalTime))
        if calendarId.isEmpty {
            observable = api.getPrimaryCalendarID().flatMapLatest { (primaryCalendarId) -> Observable<(Bool, Any?)> in
                return api.isRSVPCardRemoved(calendarID: primaryCalendarId, key: key, originalTime: Int64(originalTime))
            }
        }
        observable
             .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (result, entity) in
                 guard let `self` = self else { return }
                 let modelValue = self.model.value
                 if !result {
                    let detailVC = self.getRsvpDetailController(entity, self.getReplyStasusString(status: modelValue.status, rsvpCommentUser: modelValue.rsvpCommentUserName))
                     self.jumpToDetail(detailVC)
                 } else if let view = self.controllerGetter().view {
                    if entity != nil {
                        RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_Common_EventHasBeenDeleteTip, on: view)
                    } else {
                        RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_Transfer_eventNoLongerExist, on: view)
                    }
                 }
             }, onError: { [weak self] (error) in
                if let view = self?.controllerGetter().view {
                    RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Common_EventHasBeenDeleteTip, on: view)
                }
             }).disposed(by: disposeBag)
    }

    private func jumpToNormalEventDetail(key: String, calendarId: String, originalTime: Int) {
        let detailVC = self.getNormalDetailController(key, calendarId, Int64(originalTime), nil, nil, .invite, .inviteCard)
        self.api?.isEventRemoved(key: key, calendarId: calendarId, originalTime: Int64(originalTime))
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (result) in
                if !result {
                    self?.jumpToDetail(detailVC)
                } else if let view = self?.controllerGetter().view {
                    RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_Common_EventHasBeenDeleteTip, on: view)
                }
            }, onError: { [weak self] (error) in
                if let view = self?.controllerGetter().view {
                    RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Common_EventHasBeenDeleteTip, on: view)
                }
            }).disposed(by: disposeBag)
    }

    private func detailAction(model: InviteEventCardModel) {
        guard let calendarId = model.calendarID,
            let key = model.key,
            let originalTime = model.originalTime
            else {
                assertionFailureLog("\(model.calendarID)-\(model.key)-\(model.originalTime)")
                return
        }

        let messageType = self.map(messageType: model.messageType)
        let messageTypeStr = messageType == .transferEvent ? "transfer_event" : "invitation"
        let botCardTypeStr: String
        if model.isInvalid {
            botCardTypeStr = "out_of_date"
        } else {
            botCardTypeStr = messageType == .eventInvite ? "initial" : "update"
        }
        CalendarTracer.shareInstance.calOpenEventDetail(
            cardMessageType: messageTypeStr,
            botCardType: botCardTypeStr,
            eventServerID: model.eventServerID,
            isCrossTenant: model.isCrossTenant
        )

        switch messageType {
        case .transferEvent, .switchCalendar:
            self.jumpToTransferEventDetail(key: key, calendarId: calendarId, originalTime: originalTime)
        case .rsvpComment:
            self.api?.getPrimaryCalendarID().subscribe(
                onNext: {[weak self] (event) in
                    self?.jumpToRsvpEventDetail(key: key, calendarId: event, originalTime: originalTime)
                }
            ).disposed(by: self.disposeBag)
        default:
            self.jumpToNormalEventDetail(key: key, calendarId: calendarId, originalTime: originalTime)
        }
    }

    private func jumpToDetail(_ detail: UIViewController) {
        if Display.pad {
            let nav = LkNavigationController(rootViewController: detail)
            nav.update(style: .default)
            detail.modalPresentationStyle = .formSheet
            nav.modalPresentationStyle = .formSheet
            self.controllerGetter().present(nav, animated: true)
        } else {
            self.controllerGetter().navigationController?.pushViewController(detail, animated: true)
        }
    }

    private func changeEventStatus(status: CalendarEventAttendee.Status) {
        ReciableTracer.shared.recStartBotReply()
        let modelValue = model.value
        CalendarMonitorUtil.startTrackRsvpEventBotCardTime(calEventId: modelValue.eventServerID, originalTime: Int64(modelValue.originalTime ?? 0), uid: modelValue.key ?? "")
        guard let calendarId = modelValue.calendarID,
            let key = modelValue.key,
            let originalTime = modelValue.originalTime else {
                assertionFailureLog("\(modelValue.calendarID)-\(modelValue.key)-\(modelValue.originalTime)")
                return
        }

        let hud = RoundedHUD()
        hud.showLoading(with: BundleI18n.Calendar.Calendar_Toast_ReplyingMobile,
                        on: controllerGetter().view,
                        disableUserInteraction: true)
        self.api?.replyCalendarEventInvitation(
            calendarId: calendarId,
            key: key,
            originalTime: Int64(originalTime),
            comment: "",
            inviteOperatorID: "",
            replyStatus: status,
            messageId: modelValue.messageId)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] (_, _, errorCodes) in
                    guard let self = self else { return }
                    if errorCodes.contains(where: { ErrorType(rawValue: $0) == .invalidCipherFailedToSendMessage }) {
                        UDToast.showFailure(with: I18n.Calendar_KeyNoToast_CannoReply_Pop, on: self.controllerGetter().view)
                    }
                    CalendarTracer.shareInstance.calEventResp(replyStatus: status)
                    self.showSuccess(hud: hud, on: self.controllerGetter().view, status: status)
                    self.localRefreshService?.rxEventNeedRefresh.onNext(())
                    self.model.value.status = status
                    self.reloadViewPublish.onNext(())
                    CalendarMonitorUtil.endTrackRsvpEventBotCardTime()
                    ReciableTracer.shared.recEndBotReply()
                }, onError: {[weak self] (error) in
                    self?.showFailure(hud: hud, on: self?.controllerGetter().view, error: error)
                    ReciableTracer.shared.recTracerError(errorType: ErrorType.Unknown,
                                                         scene: Scene.CalBot,
                                                         event: .replyRsvp,
                                                         userAction: "cal_reply_rsvp",
                                                         page: "cal_bot_card",
                                                         errorCode: Int(error.errorCode() ?? 0),
                                                         errorMessage: error.getMessage() ?? "")
                }, onDisposed: { [weak self] in
                    if self == nil { hud.remove() }
                }
            )
            .disposed(by: self.disposeBag)
        self.traceReplyEventNew(calendarID: calendarId, key: key, originalTime: Int64(originalTime), messageID: modelValue.messageId, status: status)
    }

    private func traceReplyEventNew(calendarID: String,
                                    key: String,
                                    originalTime: Int64,
                                    messageID: String?,
                                    status: CalendarEventAttendee.Status) {
        self.api?.getRemoteEvent(calendarID: calendarID, key: key, originalTime: originalTime, token: nil, messageID: messageID)
            .observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] result in
            guard let self = self else { return }
            let modelValue = self.model.value
            CalendarTracer.shared.calReplyEventInCard(event: result.event, status: status, chatId: modelValue.chatId, cardMessageType: .invitation)
        })
    }

    private func showSuccess(hud: RoundedHUD, on view: UIView?, status: CalendarEventAttendee.Status) {
        DispatchQueue.main.asyncAfter(deadline: .now() + self.delay, execute: {
            if let view = view {
                hud.showSuccess(with: status.rsvpSelectedToast, on: view)
            }
        })
    }

    private func showFailure(hud: RoundedHUD, on view: UIView?, error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            if let view = view {
                hud.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Detail_ResponseFailed, on: view)
            }
        })
    }
}

#if !LARK_NO_DEBUG
extension EventCardBinder: ConvenientDebug {}
#endif
