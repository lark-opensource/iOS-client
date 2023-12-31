//
//  CalendarChatExtensionFunctionsFactory.swift
//  LarkChatSetting
//
//  Created by zc09v on 2020/5/18.
//
import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkBadge
import LarkAccountInterface
import LarkContainer
import RxRelay
import LarkCore
import LarkFeatureGating
import LarkNavigator
import LKCommonsTracker
import Homeric
import LarkUIKit
import LarkMessengerInterface
import LKCommonsLogging
import SuiteAppConfig
import Swinject
import EENavigator

final class CalendarChatExtensionFunctionsFactory: NSObject, ChatExtensionFunctionsFactory {
    init(userResolver: LarkContainer.UserResolver) {
        self.userResolver = userResolver
    }

    let userResolver: LarkContainer.UserResolver

    private let functionsRelay: BehaviorRelay<[ChatExtensionFunction]> = BehaviorRelay<[ChatExtensionFunction]>(value: [])
    private let disposeBag = DisposeBag()
    private var calendarFreeBusy: ChatExtensionFunction?
    private var meetingMinutesBadgeService: MeetingMinutesBadgeService?
    private var meetingInfo: MeetingInfo?
    private static let logger = Logger.log(CalendarChatExtensionFunctionsFactory.self, category: "ChatExtensionFunctionsFactory")
    @ScopedInjectedLazy var dependency: ChatSettingCalendarDependency?
    public var currentChatterId: String {
        return self.userResolver.userID
    }

    func createExtensionFuncs(chatWrapper: ChatPushWrapper,
                              pushCenter: PushNotificationCenter,
                              rootPath: Path) -> Observable<[ChatExtensionFunction]> {
        let chat = chatWrapper.chat.value
        if chat.chatMode == .threadV2 || chat.isP2PAi {
            return .just([])
        }
        if showFreeBusy(chat) {
            let calendarFreeBusyTitle = chat.type == .group ?
                BundleI18n.LarkChatSetting.Calendar_ChatFindTime_FindTimePlural : BundleI18n.LarkChatSetting.Calendar_ChatFindTime_FindTimeSingle
            let image = Resources.freeBusy_chatExFunc
            let isOwner = currentChatterId == chat.ownerId
            self.calendarFreeBusy = ChatExtensionFunction(type: .freeBusyInChat,
                                                          title: calendarFreeBusyTitle,
                                                          imageInfo: .image(image),
                                                          badgePath: rootPath.raw(ChatExtensionFunctionType.freeBusyInChat.rawValue)) { [weak self] vc in
                self?.pushFreeBusy(vc, chat: chatWrapper.chat.value)
                NewChatSettingTracker.imChatCalClick(chat: chat, isAdmin: isOwner)
            }
            if let calendarFreeBusy {
                functionsRelay.accept([calendarFreeBusy])
            }
        }
        // 收到isMeeting变化后，刷新UI为普通群。for 会议群转普通群
        // 监听会议群转普通群
        chatWrapper.chat.distinctUntilChanged { (chat1, chat2) -> Bool in
            return chat1.isMeeting == chat2.isMeeting || chat2.isMeeting == true
        }.skip(1).subscribe(onNext: { [weak self] (chat) in
            self?.createFunctions(shouldDisplayEventSideItem: false, chat: chat, rootPath: rootPath, isEventOpen: false)
        }).disposed(by: self.disposeBag)

        if chat.isMeeting {
            dependency?
                .getEventInfo(chatId: chat.id)
                .subscribe(onNext: { [weak self] (eventInfo) in
                    //确定event存在才能展示侧边栏event item
                    self?.generateMeetingMinutesBadgeManager(chatId: chat.id,
                                                             rootPath: rootPath)
                    if eventInfo?.meetingInfo != nil {
                        self?.meetingInfo = eventInfo?.meetingInfo
                        self?.createFunctions(shouldDisplayEventSideItem: true, chat: chat, rootPath: rootPath, isEventOpen: true, docUrl: eventInfo?.url)
                    } else {
                        self?.createFunctions(shouldDisplayEventSideItem: true, chat: chat, rootPath: rootPath, isEventOpen: false, docUrl: eventInfo?.url)
                        CalendarChatExtensionFunctionsFactory.logger.info("GetMeetingEventInfo not return timeInfo \(chat.id)")
                    }
            }, onError: { (error) in
                CalendarChatExtensionFunctionsFactory.logger.error("GetMeetingEventInfo error \(chat.id)", error: error)
            }).disposed(by: self.disposeBag)
        }
        return functionsRelay.asObservable()
    }

    private func generateMeetingMinutesBadgeManager(chatId: String, rootPath: Path) {
        if self.meetingMinutesBadgeService == nil {
            self.meetingMinutesBadgeService = try? self.userResolver.resolve(type: MeetingMinutesBadgeService.self, arguments: chatId, rootPath)
            self.meetingMinutesBadgeService?.startMonitorMeetingSummaryBadge()
        }
    }

    private func showFreeBusy(_ chat: Chat) -> Bool {
        let chatWithMyself = self.currentChatterId == chat.chatter?.id
        return !chat.isOncall &&
            chat.userCount < 1000 && !chat.isSingleBot
            && !chat.isCustomerService
            && !chat.isCrypto && !chatWithMyself
            && chat.chatMode != .threadV2 && !chat.chatterHasResign && !chat.isSuper
    }

    func createFunctions(shouldDisplayEventSideItem: Bool, chat: Chat, rootPath: Path, isEventOpen: Bool, docUrl: URL? = nil) {
        var functions: [ChatExtensionFunction] = []
        if let calendarFreeBusy = self.calendarFreeBusy {
            functions.append(calendarFreeBusy)
        }
        guard shouldDisplayEventSideItem else {
            functionsRelay.accept(functions)
            return
        }

        if isEventOpen {
            let image = Resources.event_chatExFunc
            let isOwner = currentChatterId == chat.ownerId
            let event = ChatExtensionFunction(type: .event,
                                              title: BundleI18n.LarkChatSetting.Lark_Legacy_SideEvent,
                                              imageInfo: .image(image),
                                              badgePath: rootPath.raw(ChatExtensionFunctionType.event.rawValue)) { [weak self] vc in
                self?.pushEvent(vc, chat: chat)
                NewChatSettingTracker.imChatEventClick(chatId: chat.id, isAdmin: isOwner)
                NewChatSettingTracker.imChatSettingClickDetailView(chat: chat)
            }
            functions.append(event)
        }

        if let urlString = docUrl {
            let image = Resources.meetingSummary_chatExFunc
            let badgePath = rootPath.raw(ChatExtensionFunctionType.meetingSummary.rawValue)
            let meetingSummary = ChatExtensionFunction(type: .meetingSummary,
                                                       title: BundleI18n.LarkChatSetting.Calendar_MeetingNotes_MeetingNotes,
                                                       imageInfo: .image(image),
                                                       badgePath: badgePath) { [weak self] vc in
                self?.pushMeetingSummary(vc, chat: chat, meetingMinutesUrl: urlString, badgePath: badgePath)
                NewChatSettingTracker.imChatMinutesClick(chatId: chat.id, isAdmin: self?.currentChatterId == chat.ownerId)
                NewChatSettingTracker.imChatSettingClickCalView(chat: chat)
            }
            functions.append(meetingSummary)
        }
        functionsRelay.accept(functions)
    }

    func pushFreeBusy(_ controller: UIViewController?, chat: Chat) {
        guard let controller = controller else { return }
        let type = chat.trackType == "single" ? "single" : "group"
        Tracker.post(TeaEvent(Homeric.CAL_SIDEBAR_FUNCTION, params: ["event_sidebar": "findtime",
                                                                     "group_type": "\(type)"]))
        let displayStyle: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        let param = PresentParam(from: controller, prepare: { $0.modalPresentationStyle = displayStyle })
        let wrapperPresentParam = PresentParam(wrap: LkNavigationController.self,
                                               from: param.from,
                                               prepare: param.prepare)
        dependency?.presentFreeBusyGroup(chatId: chat.id, chatType: type, presentParam: wrapperPresentParam)
        trackSidebarClick(chat: chat, type: .freeBusyInChat)
    }

    func pushEvent(_ controller: UIViewController?, chat: Chat) {
        guard let controller = controller else { return }
        let params = PresentParam(wrap: LkNavigationController.self, from: controller, prepare: { (controller) in
            let displayStyle: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            controller.modalPresentationStyle = displayStyle
        })
        dependency?.presentEventDetail(chatId: chat.id, presentParam: params)
        trackSidebarClick(chat: chat, type: .event)
    }

    func pushMeetingSummary(_ controller: UIViewController?, chat: Chat, meetingMinutesUrl: URL, badgePath: Path) {
        guard let controller = controller else { return }

        //埋点逻辑
        let tl = Int64(Date().timeIntervalSince1970)
        if let meetingInfo = self.meetingInfo, let badgeStatus = meetingMinutesBadgeService?.meetingMinutesStatus.rawValue {
            let isMeetingInProgress = tl < meetingInfo.endTime && tl > meetingInfo.startTime
            Tracker.post(TeaEvent(Homeric.CAL_MTGSIDEBAR_DOCS, params: [
                "status_type": isMeetingInProgress ? "mtg" : "nomtg",
                "edit_type": badgeStatus
                ])
            )
            self.badgeShow(for: badgePath, show: false)
        }
        let params = PushParam(from: controller)

        self.userResolver.navigator.push(meetingMinutesUrl, from: params.from, animated: true)
        trackSidebarClick(chat: chat, type: .meetingSummary)
    }
}

final class MeetingMinutesBadgeServiceImp: MeetingMinutesBadgeService {
    private let disposeBag = DisposeBag()
    private let meetingSummaryPath: Path
    private static let meetingSummaryKey = "meetingSummary"
    private let calendarInterface: ChatSettingCalendarDependency
    private let chatId: String

    private var meetingEditingStatusTimer: Timer?
    var meetingMinutesStatus: MeetingMinutesBadgeStatus = .none

    init(chatId: String,
         calendarInterface: ChatSettingCalendarDependency,
         rootPath: Path) {
        self.chatId = chatId
        self.calendarInterface = calendarInterface
        self.meetingSummaryPath = rootPath.raw(Self.meetingSummaryKey)
    }

    func startMonitorMeetingSummaryBadge() {
        //每10分钟进行一次轮询
        let timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: false) { [weak self] (timer) in
            guard let `self` = self else {
                timer.invalidate()
                return
            }
            self.calendarInterface.getMeetingSummaryBadgeStatus(self.chatId) { [weak self] (result) in
                if let shouldShow = try? result.get() {
                    self?.shouldShowDocsBadge(shouldShow)
                    //                    self.showDocsEditingBadge()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()

        //接受来自日历sdk的推送
        calendarInterface.registerMeetingSummaryPush().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, weak timer] (chatId, expireTime) in
            guard let `self` = self, chatId == self.chatId else {
                return
            }
            timer?.invalidate()
            self.showDocsEditingBadge()
            self.meetingEditingStatusTimer?.invalidate() //
            let meetingEditingStatusTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(expireTime), repeats: false, block: { [weak self] (timer) in
                guard let `self` = self else {
                    timer.invalidate()
                    return
                }
                self.hideDocsEditingBadge()
                RunLoop.main.add(timer, forMode: .common)
            })
            self.meetingEditingStatusTimer = meetingEditingStatusTimer
            RunLoop.main.add(meetingEditingStatusTimer, forMode: .common)
        }).disposed(by: disposeBag)
    }

    private func shouldShowDocsBadge(_ shouldShow: Bool) {
        if shouldShow {
            BadgeManager.setBadge(meetingSummaryPath, type: .dot(.pin))
            meetingMinutesStatus = .unread
        } else {
            BadgeManager.clearBadge(meetingSummaryPath)
            meetingMinutesStatus = .none
        }
    }

    private func showDocsEditingBadge() {
        BadgeManager.setBadge(meetingSummaryPath, type: .image(.default(.edit)))
        meetingMinutesStatus = .editing
    }

    private func hideDocsEditingBadge() {
        BadgeManager.clearBadge(meetingSummaryPath)
        meetingMinutesStatus = .none
    }
}
