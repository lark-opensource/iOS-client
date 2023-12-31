//
//  EventShareBinder.swift
//  Pods
//
//  Created by zoujiayi on 2019/6/27.
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

public typealias ShareCardDetailControllerGetter = (DetailControllerGetterModel) -> UIViewController

public final class EventShareBinder: UserResolverWrapper {
    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?

    private let primaryCalendarID: String

    public var userResolver: UserResolver

    init(userResolver: UserResolver,
         model: ShareEventCardModel,
         currentTenantId: String,
         primaryCalendarID: String,
         controllerGetter: @escaping () -> UIViewController,
         detailControllerGetter: @escaping ShareCardDetailControllerGetter,
         is12HourStyle: BehaviorRelay<Bool>) {
        self.userResolver = userResolver
        self.controllerGetter = controllerGetter
        self.model = model
        self.currentTenantId = currentTenantId
        self.primaryCalendarID = primaryCalendarID
        self.detailControllerGetter = detailControllerGetter
        self.is12HourStyle = is12HourStyle
    }
    private let lock = DispatchSemaphore(value: 1)
    private var model: ShareEventCardModel
    private var controllerGetter: () -> UIViewController
    private let currentTenantId: String
    private let detailControllerGetter: ShareCardDetailControllerGetter
    private let is12HourStyle: BehaviorRelay<Bool>
    private let disposeBag = DisposeBag()
    private var handelingUrlTap: Bool = false
    public let reloadViewPublish = PublishSubject<Void>()
    private let delay: TimeInterval = 0.5

    public var componentProps: ShareCardComponentProps {
        let props = ShareCardComponentProps()

        let tenant = Tenant(currentTenantId: currentTenantId)
        let shouldShowExternalLabel = tenant.isExternalTenant(isCrossTenant: model.isCrossTenant)

        // for header
        props.summary = getTitle(isInvalid: model.isInvalid, title: model.title)
        props.isShowOptional = false
        props.isShowExternal = shouldShowExternalLabel
        props.isVaild = !model.isInvalid
        // for time
        props.time = model.getTime(is12HourStyle: is12HourStyle.value)
        props.conflictText = model.getConflictText(is12HourStyle: is12HourStyle.value)

        // for location
        props.location = (!model.isInvalid && model.isJoined) ? model.location : nil

        // for meeting room
        props.meetingRooms = model.isJoined ? model.meetingRoom : nil

        // for repeat
        props.repeatText = model.getRepeatText()

        // for padding
        props.needBottomPadding = model.hasReaction

        // for action
        props.joinSelector = #selector(joinTapped)
        props.isJoined = model.isJoined
        props.joinTarget = self

        // for rsvp
        props.rsvpStatus = model.status
        props.rsvpTarget = self
        props.declinSelector = #selector(declineTapped)
        props.tentativeSelector = #selector(tentativeTapped)
        props.acceptSelector = #selector(acceptTapped)
        props.replyedBtnRetapSelector = #selector(repleyRetapped)
        props.moreReplyeTappedSelector = #selector(moreRepleyTapped)

        props.tapDetail = { [weak self] in
            self?.goDetail()
        }

        #if !LARK_NO_DEBUG
        // Convenient Debug - EventShareCard
        props.showDebugInfo = { [weak self] () in
            guard FG.canDebug,
                  let self = self else { return }
            self.showInfo(info: self.model.debugDescription, in: self.controllerGetter())
        }
        #endif

        props.relationTag = model.relationTag

        return props
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


    public func updateModel(_ model: ShareEventCardModel) {
        lock.wait()
        defer { lock.signal() }
        self.model = model
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

    private func tapAccept() {
        CalendarTracerV2.EventCard.traceClick {
            $0.click("accept").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.model))
            $0.chat_id = self.model.chatId
            $0.is_invited = self.model.isJoined.description
            $0.is_updated = false.description
            $0.event_type = self.model.isWebinar ? "webinar" : "normal"
            $0.is_new_card_type = "false"
            $0.is_support_reaction = "false"
            $0.is_bot = "false"
            $0.is_share = "true"
            $0.is_reply_card = self.model.isJoined.description
        }
        changeEventStatus(status: .accept)
    }

    private func tapDecline() {
        CalendarTracerV2.EventCard.traceClick {
            $0.click("reject").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.model))
            $0.chat_id = self.model.chatId
            $0.is_invited = self.model.isJoined.description
            $0.is_updated = false.description
            $0.event_type = self.model.isWebinar ? "webinar" : "normal"
            $0.is_new_card_type = "false"
            $0.is_support_reaction = "false"
            $0.is_bot = "false"
            $0.is_share = "true"
            $0.is_reply_card = self.model.isJoined.description
        }
        changeEventStatus(status: .decline)
    }

    private func tapTentative() {
        CalendarTracerV2.EventCard.traceClick {
            $0.click("not_determined").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.model))
            $0.chat_id = self.model.chatId
            $0.is_invited = self.model.isJoined.description
            $0.is_updated = false.description
            $0.event_type = self.model.isWebinar ? "webinar" : "normal"
            $0.is_new_card_type = "false"
            $0.is_support_reaction = "false"
            $0.is_bot = "false"
            $0.card_value = ""
            $0.is_share = "true"
            $0.is_reply_card = self.model.isJoined.description
        }
        changeEventStatus(status: .tentative)
    }

    private func changeEventStatus(status: CalendarEventAttendee.Status) {
        ReciableTracer.shared.recStartBotReply()
        CalendarMonitorUtil.startTrackRsvpEventBotCardTime(calEventId: model.eventID, originalTime: Int64(model.originalTime), uid: model.key)
        let calendarId = model.currentUsersMainCalendarId
        let key = model.key
        let originalTime = model.originalTime

        let hud = RoundedHUD()
        hud.showLoading(with: BundleI18n.Calendar.Calendar_Toast_ReplyingMobile,
                        on: controllerGetter().view,
                        disableUserInteraction: true)
        api?.replyCalendarEventInvitation(
            calendarId: calendarId,
            key: key,
            originalTime: Int64(originalTime),
            comment: "",
            inviteOperatorID: "",
            replyStatus: status,
            messageId: model.messageId)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] (_, _, errorCodes) in
                    guard let self = self else { return }
                    if errorCodes.contains(where: { ErrorType(rawValue: $0) == .invalidCipherFailedToSendMessage }) {
                        UDToast.showFailure(with: I18n.Calendar_KeyNoToast_CannoReply_Pop, on: self.controllerGetter().view)
                    }
                    CalendarTracer.shareInstance.calEventResp(replyStatus: status)
                    self.showSuccess(hud: hud, status: status)
                    self.localRefreshService?.rxEventNeedRefresh.onNext(())
                    self.model.status = status
                    self.reloadViewPublish.onNext(())
                    CalendarMonitorUtil.endTrackRsvpEventBotCardTime()
                    ReciableTracer.shared.recEndBotReply()
                }, onError: {[weak self] (error) in
                    self?.showFailure(hud: hud, error: error)
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
        self.traceReplyEventNew(calendarID: calendarId, key: key, originalTime: Int64(originalTime), messageID: model.messageId, status: status)
    }

    private func traceReplyEventNew(calendarID: String,
                                    key: String,
                                    originalTime: Int64,
                                    messageID: String?,
                                    status: CalendarEventAttendee.Status) {
        guard let api = self.api else { return }
        api.getRemoteEvent(calendarID: calendarID, key: key, originalTime: originalTime, token: nil, messageID: messageID)
            .observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] result in
            guard let self = self else { return }
            CalendarTracer.shared.calReplyEventInCard(event: result.event, status: status, chatId: self.model.chatId, cardMessageType: .shareEvent)
        })
    }

    private func showSuccess(hud: RoundedHUD, status: CalendarEventAttendee.Status) {

        DispatchQueue.main.asyncAfter(deadline: .now() + self.delay, execute: {
            hud.showSuccess(with: status.rsvpSelectedToast, on: self.controllerGetter().view)
        })
    }

    private func showFailure(hud: RoundedHUD, error: Error) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            hud.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Detail_ResponseFailed, on: self.controllerGetter().view)
        })
    }

    private func goDetail() {
        guard !model.isInvalid else {
            return
        }
        if self.handelingUrlTap {
            self.handelingUrlTap = false
            return
        }

        let model = DetailControllerGetterModel(scene: .shareCard, 
                                                key: self.model.key,
                                                calendarId: self.model.calendarID,
                                                source: "",
                                                originalTime: Int64(self.model.originalTime),
                                                startTime: self.model.startTime ?? 0,
                                                endTime: self.model.endTime ?? 0,
                                                isJoined: self.model.isJoined,
                                                messageId: self.model.messageId,
                                                token: nil,
                                                joinEventAction: self.joinClosure())
        let detailController = self.detailControllerGetter(model)

        CalendarTracerV2.EventCard.traceClick {
            $0.click("check_more_detail").target("cal_event_detail_view")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.model))
            $0.chat_id = self.model.chatId
            $0.is_invited = self.model.isJoined.description
            $0.is_updated = false.description
            $0.event_type = self.model.isWebinar ? "webinar" : "normal"
            $0.is_new_card_type = "false"
            $0.is_support_reaction = "false"
            $0.is_bot = "false"
            $0.is_share = "true"
            $0.is_reply_card = self.model.isJoined.description
        }

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
        self.handelingUrlTap = true
        CalendarTracerV2.EventCard.traceClick {
            $0.click("join_event").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.model))
            $0.chat_id = self.model.chatId
            $0.is_invited = self.model.isJoined.description
            $0.is_updated = false.description
            $0.event_type = self.model.isWebinar ? "webinar" : "normal"
            $0.is_new_card_type = "false"
            $0.is_support_reaction = "false"
            $0.is_bot = "false"
            $0.is_share = "true"
            $0.is_reply_card = self.model.isJoined.description
        }
        self.join(success: { [weak self] () in
                // update
                self?.reloadViewPublish.onNext(())
            }, failure: { [weak self] _ in
                self?.reloadViewPublish.onNext(())
        }, disposeBag: disposeBag, is12HourStyle: is12HourStyle.value)
    }

    private func join(success: @escaping () -> Void,
                      failure: ((Error) -> Void)? = nil,
                      disposeBag: DisposeBag, is12HourStyle: Bool) {
        var content = self.model
        if content.isJoined { return }
        let hud = RoundedHUD()
        hud.showLoading(with: BundleI18n.Calendar.Calendar_Share_Joining, on: controllerGetter().view, disableUserInteraction: false)

        CalendarMonitorUtil.startJoinEventTime(extraName: "msg_card",
                                               calEventID: content.eventID,
                                               originalTime: Int64(content.originalTime),
                                               uid: content.key)
        api?.joinToEvent(calendarID: content.calendarID, key: content.key, token: nil, originalTime: Int64(content.originalTime), messageID: content.messageId)
            .subscribe(onNext: {[weak self] (data) in
                guard let self = self else { return }
                let primaryCalendarID = self.primaryCalendarID
                switch data {
                case .event:
                    DispatchQueue.main.async(execute: {
                        hud.showSuccess(with: BundleI18n.Calendar.Calendar_Share_JoinSucTip, on: self.controllerGetter().view)
                        self.model.isJoined = true
                        success()
                        CalendarMonitorUtil.endJoinEventTime(isSuccess: true, errorCode: "")
                        CalendarTracer.shareInstance.joinFromShare()
                        CalendarTracer.shareInstance
                            .calJoinEvent(
                                actionSource: .cardMessage,
                                eventType: .event,
                                eventId: content.eventID,
                                isCrossTenant: self.model.isCrossTenant,
                                chatId: content.chatId)
                    })
                case .joinFailedData(let failedData):
                    CalendarMonitorUtil.endJoinEventTime(isSuccess: false, errorCode: "")
                    DispatchQueue.main.async(execute: {
                        let role = content.calendarID == primaryCalendarID ? "organizer" : "guest"
                        CalendarTracerV2.EventAttendeeReachLimit.traceView {
                            $0.content = "cannot_join_event"
                            $0.role = role
                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.model))
                        }
                        let alertVC = UDDialog(config: UDDialogUIConfig())
                        alertVC.setTitle(text: I18n.Calendar_G_CantJoinEvent_Pop)
                        alertVC.setContent(text: I18n.Calendar_G_CantJoinEvent_Explain(number: failedData.controlMaxAttendeeNum))
                        alertVC.addPrimaryButton(text: I18n.Calendar_Common_GotIt, dismissCompletion: {
                            CalendarTracerV2.EventAttendeeReachLimit.traceClick {
                                $0.click("confirm").target("none")
                                $0.content = "cannot_join_event"
                                $0.role = role
                                $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.model))
                            }
                        })
                        hud.remove()
                        self.controllerGetter().present(alertVC, animated: true, completion: nil)
                    })
                case .none:
                    assertionFailure()
                @unknown default: break
                }
            }, onError: { (error) in
                CalendarMonitorUtil.endJoinEventTime(isSuccess: true, errorCode: "\(error.errorCode())")
                // 无加入权限弹窗
                let errorType = error.errorType()
                if errorType == .joinEventNoPermissionErr {
                    DispatchQueue.main.async(execute: {
                        let alertVC = UDDialog(config: UDDialogUIConfig())
                        alertVC.setContent(text: I18n.Calendar_Share_UnableToJoinEvent)
                        alertVC.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
                        hud.remove()
                        self.controllerGetter().present(alertVC, animated: true, completion: nil)
                    })
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        hud.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Share_JoinFailedTip, on: self.controllerGetter().view)
                        failure?(error)
                    })
                }
            }, onDisposed: { [weak disposeBag] in
                if disposeBag == nil {
                    hud.remove()
                }
            }).disposed(by: disposeBag)
    }

    private func getTitle(isInvalid: Bool, title: String) -> String {
        let title = title.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : title

        if isInvalid {
            return I18n.Calendar_G_CanceledEvent(event: title)
        }
        return title
    }
}
