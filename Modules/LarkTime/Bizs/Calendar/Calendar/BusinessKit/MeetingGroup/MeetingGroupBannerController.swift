//
//  MeetingGroupBannerController.swift
//  Calendar
//
//  Created by zhu chao on 2018/9/25.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import RustPB
import ServerPB
import RxCocoa
import LarkActionSheet
import RoundedHUD
import LarkUIKit
import LarkAlertController
import UniverseDesignToast
import LarkContainer
import LKCommonsLogging

final class MeetingGroupBannerController: UserResolverWrapper {
    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarAPI: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarInterface: CalendarInterface?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var rustPushService: RustPushService?

    typealias CalendarEventInstanceView = ServerPB.ServerPB_Entities_ChatCalendarEventInstanceView
    static let logger = Logger.log(MeetingGroupBannerController.self, category: "lark.calendar.banner")

    private var chatId: String
    private let disposeBag = DisposeBag()
    private var floatCard: BaseMeetingFloatCardView?
    private var eventInstanceView: CalendarEventInstanceView?
    private var meeting: ServerPB_Entities_Meeting?
    private let chatTitle: String
    public var onBannerClosed: (() -> Void)?
    public var onBannerChanged: (() -> Void)?
    public var instanceStartTime: TimeInterval {
        guard let startTime = eventInstanceView?.startTime else {
            assertionFailureLog()
            return Date().timeIntervalSince1970
        }
        return TimeInterval(startTime)
    }

    public var instanceEndTime: TimeInterval {
        guard let endTime = eventInstanceView?.endTime else {
            assertionFailureLog()
            return Date().timeIntervalSince1970
        }
        return TimeInterval(endTime)
    }

    public var instanceViewTitle: String {
        if let summary = eventInstanceView?.summary, !summary.isEmpty {
            return summary
        }
        return I18n.Calendar_Common_NoTitle
    }

    private func closeFloatObserver() {
        rustPushService?.rxMeetingBannerClosed.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (chatId, scrollType) in
            guard let `self` = self, let meeting = self.meeting else {
                return
            }
            if chatId == self.chatId && scrollType == meeting.scrollType {
                self.eventDetailClose()
            }
        }).disposed(by: disposeBag)
    }

    private func observeBannerChanged() {
        rustPushService?.rxMeetingChatBannerChanged.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (response) in
            guard let self, let meeting = self.meeting else { return }
            if !response.chatIds.contains(self.chatId) { return }
            Self.logger.info("banner info changed: update banner info chatId:\(self.chatId) meetingId:\(meeting.id)")
            self.loadBanner {
                self.onBannerChanged?()
            }
        }).disposed(by: disposeBag)
    }

    init(chatId: String,
         chatTitle: String,
         userResolver: UserResolver) {
        self.chatId = chatId
        self.chatTitle = chatTitle
        self.userResolver = userResolver

        self.closeFloatObserver()
        self.observeBannerChanged()
        self.update12HourStyle()
    }

    func bannerView() -> UIView? {
        return floatCard
    }

    private func update12HourStyle() {
        calendarDependency?.is12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (is12HourStyle) in
            guard let `self` = self, let eventInstanceView = self.eventInstanceView else { return }
            if let floatCard = floatCard as? EventFloatCard {
                let titles = self.titles(from: eventInstanceView, chatTitle: self.chatTitle, is12HourStyle: is12HourStyle)
                floatCard.update(title: titles.title, subTitle: titles.subTitle, thirdTitle: titles.thirdTitle)
            }
        }).disposed(by: disposeBag)
    }

    private func getMeetingFloatCard(event: CalendarEventInstanceView, chatTitle: String) -> BaseMeetingFloatCardView {
        let is12HourStyle = calendarDependency?.is12HourStyle.value ?? true
        let titles = self.titles(from: event, chatTitle: chatTitle, is12HourStyle: is12HourStyle)
        let floatView = EventFloatCard(target: self,
                                       title: titles.title,
                                       subTitle: titles.subTitle,
                                       thirdTitle: titles.thirdTitle,
                                       detailSelector: #selector(eventDetailTapped),
                                       closeSelector: #selector(eventDetailClose))
        return floatView
    }

    private func getTransferFloatCard() -> BaseMeetingFloatCardView {
        let floatView = TransferFloatCard(target: self,
                                          transferSelector: #selector(transferMeetingTapped),
                                          closeSelector: #selector(transferMeetingClose))
        return floatView
    }

    @objc
    private func eventDetailTapped() {
        guard let eventInstanceView = self.eventInstanceView,
              let calendarInterface = self.calendarInterface,
              let viewController = self.floatCard?.viewController() else { return }

        if !eventInstanceView.isInMeetingEvent {
            Self.logger.info("user not in current event")

            if let view = viewController.view {
                UDToast.showFailure(with: I18n.Calendar_Share_SingleEventNoInfo, on: view)
                CalendarTracer.shareInstance.userNotInEventToast(chatId: self.chatId)
                self.hideFloat()
            }
            return
        }
        // 和会议群侧边栏进入日程详情页保持一致
        let controller = calendarInterface.getEventContentController(with: chatId, isFromChat: true)
        
        if Display.pad {
            let nav = LkNavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .formSheet
            nav.update(style: .default)
            self.userResolver.navigator.present(nav, from: viewController)
        } else {
            self.userResolver.navigator.push(controller, from: viewController)
        }
        self.hideFloat()
    }

    @objc
    private func eventDetailClose() {
        CalendarTracer.shareInstance.calBannerClose(bannerType: .meeting)
        removeFloatView()
    }
    
    @objc
    private func transferMeetingTapped() {
        CalendarTracerV2.MeetingGroupBannerTransfer.normalTrackClick {
            var map = [String: Any]()
            map["click"] = "trans"
            map["cal_event_id"] = Int(eventInstanceView?.calendarEventRefID ?? "") ?? 0
            map["chat_id"] = Int(self.chatId) ?? 0
            return map
        }

        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.Calendar.Calendar_Setting_ConfirmTransform)
        alertController.setContent(text: BundleI18n.Calendar.Calendar_Setting_TransformGroupConfirmSubtitle)
        alertController.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Common_Cancel, newLine: false, weight: 1, numberOfLines: 1, dismissCheck: { () -> Bool in
            CalendarTracer.shareInstance.trackToNormalGroupPopupClicked(false)
            return true
        })

        guard let controller = self.floatCard?.viewController() else { return }
        alertController.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_Confirm, dismissCompletion: { [weak self, weak controller] in
            guard let `self` = self else { return }
            CalendarTracer.shareInstance.trackToNormalGroupPopupClicked(true)
            self.calendarAPI?.transferToNormalGroup(chatID: self.chatId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.removeFloatView()
                }, onError: { [weak controller] error in
                    guard let controller else { return }
                    UDToast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationFailed,
                                        on: controller.view)
                }).disposed(by: self.disposeBag)
        })
        controller.present(alertController, animated: true)
    }

    @objc
    private func transferMeetingClose() {
        CalendarTracer.shareInstance.calBannerClose(bannerType: .toNormalGroup)
        CalendarTracerV2.MeetingGroupBannerTransfer.normalTrackClick() {
            var map = [String: Any]()
            map["click"] = "close"
            map["cal_event_id"] = Int(eventInstanceView?.calendarEventRefID ?? "") ?? 0
            map["chat_id"] = Int(self.chatId) ?? 0
            return map
        }
        removeFloatView()
    }

    private func removeFloatView() {
        floatCard?.isHidden = true
        floatCard?.removeFromSuperview()
        floatCard = nil
        if let meeting = self.meeting {
            calendarAPI?.markMeetingScrollClicked(meetingId: meeting.id, type: meeting.scrollType).subscribe(onNext: { (_) in
                Self.logger.info("removeFloatView scrollType:\(meeting.scrollType)")
            }).disposed(by: disposeBag)
        }

        onBannerClosed?()
    }

    private struct TitleTuple {
        var title: String
        var subTitle: String
        var thirdTitle: String

        init(_ title: String,
             _ subTitle: String,
             _ thirdTitle: String) {
            self.title = title
            self.subTitle = subTitle
            self.thirdTitle = thirdTitle
        }
    }

    private func titles(from eventInstanceView: CalendarEventInstanceView, chatTitle: String, is12HourStyle: Bool) -> TitleTuple {
        let title = instanceViewTitle != chatTitle ? instanceViewTitle : ""
        let subTitle = getTimeDescription(startDate: getDateFromInt64(eventInstanceView.startTime),
                                          endDate: getDateFromInt64(eventInstanceView.endTime),
                                          isAllDayEvent: eventInstanceView.isAllDay,
                                          isInOneLine: true,
                                          is12HourStyle: is12HourStyle)
        let meetintRooms = getMeetingRooms(buildings: eventInstanceView.calendarBuildings)
        let locations = getLocations(locations: eventInstanceView.locations)
        let thirdTitle = (meetintRooms + locations).joined(separator: ",")
        return TitleTuple(title,
                          subTitle,
                          thirdTitle)
    }

    private func loadEventModel(by chatId: String,
                                calendarApi: CalendarRustAPI) -> Observable<(eventInstanceView: CalendarEventInstanceView,
                                                                             meeting: ServerPB_Entities_Meeting?,
                                                                             shouldShowScroll: Bool)> {
        guard let calendarAPI = self.calendarAPI else { return .empty() }
        return Observable
            .zip(calendarAPI.getChatCalendarEventInstanceViewRequest(chatIds: [chatId]),
                 calendarAPI.transferScrollCheck(chatID: chatId)) { (eventInstanceViewResponse, shouldShowTransferScroll) in
                let chatMeetingMap = eventInstanceViewResponse.chatMeetingMap
                let chatEventInstanceTimeMap = eventInstanceViewResponse.chatEventInstanceTimeMap
                guard let eventInstanceView: CalendarEventInstanceView = chatEventInstanceTimeMap[chatId] else {
                    assertionFailureLog()
                    throw CError.custom(message: "load float event not exist")
                }
                var meeting = chatMeetingMap[chatId]
                meeting?.scrollType = shouldShowTransferScroll ? .meetingTransferChat : .eventInfo
                self.eventInstanceView = eventInstanceView
                // meeting?.shouldShowScroll只用于判断是否展示日程信息banner
                let shouldShowScroll = shouldShowTransferScroll || (meeting?.shouldShowScroll ?? false)
                Self.logger.info("loadEventModel chatId:\(chatId) scrollType:\(String(describing: meeting?.scrollType)), " +
                                 "shouldShowTransferScroll:\(shouldShowTransferScroll), shouldShowInfoBanner:\(String(describing: meeting?.shouldShowScroll))")
                return (eventInstanceView, meeting, shouldShowScroll)
            }
    }

    func loadBanner(onSucess: @escaping () -> Void) {
        operationLog(message: "try to get meeting info", optType: nil)
        guard let calendarAPI = self.calendarAPI else {
            operationLog(message: "try to get meeting info failed, can not get rustapi from larkcontainer")
            return
        }
        self.loadEventModel(by: chatId, calendarApi: calendarAPI)
            .flatMap({ [weak self] (eventInstanceView: CalendarEventInstanceView,
                                    meeting: ServerPB_Entities_Meeting?,
                                    shouldShowScroll: Bool) -> Observable<
                                        (eventInstanceView: CalendarEventInstanceView,
                                         meeting: ServerPB_Entities_Meeting?,
                                         shouldShowScroll: Bool,
                                         event: Rust.Event?)> in
                guard let self else {
                    return .just((eventInstanceView: eventInstanceView,
                                  meeting: meeting,
                                  shouldShowScroll: shouldShowScroll,
                                  event: nil))
                }

                return calendarAPI.getEventPB(calendarId: eventInstanceView.calendarID,
                                              key: eventInstanceView.uniqueKey,
                                              originalTime: eventInstanceView.originalTime).map { event in
                    (eventInstanceView: eventInstanceView, meeting: meeting, shouldShowScroll: shouldShowScroll, event: event)
                }.catchErrorJustReturn((eventInstanceView: eventInstanceView,
                                        meeting: meeting,
                                        shouldShowScroll: shouldShowScroll,
                                        event: Rust.Event()))
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else {
                    normalErrorLog("get meeting info failed: self released")
                    return
                }
                self.meeting = result.meeting
                let unableDecrypt = result.event?.displayType == .undecryptable
                let shouldShowScroll = result.shouldShowScroll && !unableDecrypt

                if shouldShowScroll {
                    if let meeting = self.meeting, meeting.scrollType == .meetingTransferChat {
                        let floatCard = self.getTransferFloatCard()
                        self.floatCard = floatCard
                        onSucess()
                    } else {
                        let floatCard = self.getMeetingFloatCard(event: result.eventInstanceView, chatTitle: self.chatTitle)
                        self.floatCard = floatCard
                        onSucess()
                    }
                }
            }, onError: { (error) in
                normalErrorLog("get meeting info failed: \(error)")
            }).disposed(by: disposeBag)
    }

    public func hideFloat() {
        floatCard?.isHidden = true
        floatCard?.removeFromSuperview()
        floatCard = nil
    }

    private func getMeetingRooms(buildings: [ServerPB_Entities_CalendarResourceBasicInfo]) -> [String] {
        return buildings.map {
            $0.floorName + "-" + $0.resourceName + "(" + String($0.capacity) + ")" + $0.cityName + $0.buildingName
        }
    }

    private func getLocations(locations: [ServerPB_Entities_CalendarEventLocation]) -> [String] {
        return locations.map { $0.name }
    }
}
