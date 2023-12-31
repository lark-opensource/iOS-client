//
//  ByteViewTabDependencyImpl.swift
//  Lark
//
//  Created by kiri on 2021/8/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTab
import EENavigator
import LarkUIKit
import LarkLocalizations
import LarkTab
import EventKit
import ByteViewCommon
import LarkContainer
import LarkAccountInterface
import LarkExtensions
import LarkEMM
import LarkSplitViewController
import AnimatedTabBar
import LarkSensitivityControl
#if MessengerMod
import LarkModel
import LarkMessengerInterface
#endif
#if CalendarMod
import Calendar
import CalendarFoundation
import LarkTimeFormatUtils
#endif
#if MinutesMod
import MinutesNavigator
#endif
import ByteViewInterface
import ByteViewSetting
import ByteViewNetwork
#if CCMMod
import LarkDocsIcon
#endif
import LarkSetting
import RxSwift
import RxRelay

final class TabDependencyImpl: TabDependency {
    let userResolver: UserResolver
    let accountInfo: AccountInfo
    let setting: UserSettingManager
    let global: TabGlobalDependency
    let httpClient: HttpClient
    let docsIconDependency: TabDocsIconDependency

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.accountInfo = try userResolver.resolve(assert: AccountInfo.self)
        self.setting = try userResolver.resolve(assert: UserSettingManager.self)
        self.httpClient = try userResolver.resolve(assert: HttpClient.self)
        self.global = TabGlobalDependencyImpl(userResolver: userResolver)
        self.docsIconDependency = try TabDocsIconDependencyImpl(userResolver: userResolver)
    }

    var router: TabRouteDependency? {
        try? userResolver.resolve(assert: TabRouteDependency.self)
    }

    var badgeService: TabBadgeService? {
        try? userResolver.resolve(assert: TabBadgeService.self)
    }

    func fg(_ key: String) -> Bool {
        if let service = try? userResolver.resolve(assert: FeatureGatingService.self) {
            return service.staticFeatureGatingValue(with: .init(stringLiteral: key))
        } else {
            return false
        }
    }

    #if LarkMod
    private lazy var larkUtil = LarkDependencyImpl(userResolver: self.userResolver)
    #else
    private lazy var larkUtil = DefaultLarkDependency(userResolver: self.userResolver)
    #endif

    func setPasteboardText(_ message: String, token: String, shouldImmunity: Bool) -> Bool {
        larkUtil.security.setPasteboardText(message, token: token, shouldImmunity: shouldImmunity)
    }

    func getPasteboardText(token: String) -> String? {
        larkUtil.security.getPasteboardText(token: token)
    }

    func shouldShowGuide(key: String) -> Bool {
        larkUtil.shouldShowGuide(key: key)
    }

    func didShowGuide(key: String) {
        larkUtil.didShowGuide(key: key)
    }

    var currentMeeting: TabMeeting? {
        try? userResolver.resolve(assert: MeetingService.self).currentMeeting?.toTab()
    }

    func createMeetingObserver() -> TabMeetingObserver {
        TabMeetingObserverImpl(userResolver: userResolver)
    }
}

private class TabDocsIconDependencyImpl: TabDocsIconDependency {
    let userResolver: UserResolver
    #if CCMMod
    let docsIconManager: DocsIconManager
    private lazy var disposeBag: DisposeBag = { DisposeBag() }()
    #endif

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        #if CCMMod
        docsIconManager = try userResolver.resolve(assert: DocsIconManager.self)
        #endif
    }

    func getDocsIconImageAsync(url: String, finish: @escaping (UIImage) -> Void) {
        #if CCMMod
        docsIconManager.getDocsIconImageAsync(iconInfo: "", url: url, shape: .SQUARE).subscribe { image in
            finish(image)
        }.disposed(by: disposeBag)
        #endif
    }
}

private class TabGlobalDependencyImpl: TabGlobalDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 是否24小时制
    var is24HourTime: Bool {
        Date.lf.is24HourTime
    }

    func formatRRuleString(rrule: String, userId: String) -> String {
        #if CalendarMod
        _ = try? userResolver.resolve(assert: CalendarInterface.self)
        guard let rRule = EKRecurrenceRule.recurrenceRuleFromString(rrule) else { return "" }
        return rRule.getReadableString()
        #else
        return ""
        #endif
    }

    func formatCalendarDateTimeRange(startTime: TimeInterval, endTime: TimeInterval) -> String {
        #if CalendarMod
        let start = Date(timeIntervalSince1970: startTime)
        let end = Date(timeIntervalSince1970: endTime)
        let is12HourStyle = !is24HourTime
        let options = Options(timeZone: .current, is12HourStyle: is12HourStyle, shouldShowGMT: false,
                              timePrecisionType: .minute, datePrecisionType: .day, dateStatusType: .absolute)
        return CalendarTimeFormatter.formatFullDateTimeRange(startFrom: start, endAt: end, isAllDayEvent: false, shouldShowTailingGMT: false, with: options)
        #else
        return DefaultDateUtil.formatCalendarDateTimeRange(startTime: startTime, endTime: endTime)
        #endif
    }

    func splitDisplayMode(for vc: UIViewController) -> SplitDisplayMode? {
        if let mode = vc.larkSplitViewController?.splitMode {
            /// YQHTODO:适配确认
            switch mode {
            case .twoOverSecondary, .twoBesideSecondary, .twoDisplaceSecondary, .oneOverSecondary, .oneBesideSecondary:
                return .allVisible
            default:
                return .other
            }
        } else {
            return nil
        }
    }

    func isByteViewTabSelected(for vc: UIViewController) -> Bool {
        let tabVc = (vc as? UITabBarController) ?? vc.tabBarController
        if let currentTab = tabVc?.animatedTabBarController?.currentTab, currentTab == .byteview {
            return true
        } else {
            return false
        }
    }

    var mainSceneWindow: UIWindow? {
        userResolver.navigator.mainSceneWindow
    }
}

final class TabRouteDependencyImpl: TabRouteDependency {
    private static let logger = Logger.getLogger("Dependency", prefix: "ByteViewTab.")
    let resolver: UserResolver
    var navigator: Navigatable { resolver.navigator }

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    /// 日程详情
    func gotoCalendarEvent(calendarID: String, key: String, originalTime: Int, startTime: Int, from: UIViewController) {
        #if CalendarMod
        Self.logger.info("gotoCalendarEvent: calendarID = \(calendarID), key = \(key), originalTime: \(originalTime), startTime: \(startTime)")
        let body = CalendarEventDetailBody(eventKey: key,
                                           calendarId: calendarID,
                                           originalTime: Int64(originalTime),
                                           startTime: Int64(startTime),
                                           sysEventIdentifier: "",
                                           isFromChat: false,
                                           isFromNotification: false)
        if ByteViewCommon.Display.pad {
            navigator.present(body: body,
                                            wrap: LkNavigationController.self,
                                            from: from,
                                            prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            navigator.push(body: body, from: from)
        }
        #endif
    }

    /// 创建日程
    func gotoCreateCalendarEvent(title: String?, startDate: Date, endDate: Date?, isAllDay: Bool, timeZone: TimeZone,
                                 from: UIViewController) {
        #if CalendarMod
        Self.logger.info("gotoCreateCalendarEvent: title = \(String(describing: title)), startDate = \(startDate), " +
                            "endDate: \(String(describing: endDate)), isAllDay: \(isAllDay), timeZone: \(timeZone)")
        let body = CalendarCreateEventBody(summary: title,
                                           startDate: startDate,
                                           endDate: endDate,
                                           isAllDay: isAllDay,
                                           timeZone: timeZone,
                                           attendees: [],
                                           perferredScene: .edit,
                                           isOpenLarkVC: true)
        navigator.present(body: body, wrap: LkNavigationController.self, from: from, prepare: {
            $0.modalPresentationStyle = ByteViewCommon.Display.pad ? .formSheet : .fullScreen
        })
        #endif
    }

    /// 创建Webinar日程
    func gotoCreateWebinarCalendarEvent(title: String?, startDate: Date, endDate: Date?, isAllDay: Bool, timeZone: TimeZone, from: UIViewController) {
        #if CalendarMod
        Self.logger.info("gotoCreateWebinarCalendarEvent: title = \(String(describing: title)), startDate = \(startDate), " +
            "endDate: \(String(describing: endDate)), isAllDay: \(isAllDay), timeZone: \(timeZone)")
        let body = CalendarCreateEventBody(summary: title,
                                           startDate: startDate,
                                           endDate: endDate,
                                           isAllDay: isAllDay,
                                           timeZone: timeZone,
                                           attendees: [],
                                           perferredScene: .webinar,
                                           isOpenLarkVC: true)
        navigator.present(body: body, wrap: LkNavigationController.self, from: from, prepare: {
            $0.modalPresentationStyle = ByteViewCommon.Display.pad ? .formSheet : .fullScreen
        })
        #endif
    }

    /// 个人信息
    func gotoUserProfile(userId: String, meetingTopic: String, sponsorName: String, sponsorId: String, meetingId: String,
                         from: UIViewController) {
        #if MessengerMod
        Self.logger.info("gotoUserProfile: \(userId), topic = \(meetingTopic), meetingId = \(meetingId), sponsor = \(sponsorId), \(sponsorName)")
        let sender = meetingTopic.isEmpty ? sponsorName : ""
        let body = PersonCardBody(chatterId: userId, chatId: "", fromWhere: .none, senderID: sponsorId, sender: sender,
                                  sourceID: meetingId, sourceName: meetingTopic, source: .vc)
        navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: from,
                                       prepareForPresent: { vc in vc.modalPresentationStyle = .formSheet })
        #endif
    }

    /// 切换至日历tab首页
    func gotoCalendarTab(from: UIViewController) {
        #if CalendarMod
        Self.logger.info("gotoCalendarTab")
        navigator.switchTab(Tab.calendar.url, from: from, animated: true, completion: nil)
        #endif
    }

    /// 跳转到MM
    func gotoMinutesHome(from: UIViewController, isFromTab: Bool) {
        #if MinutesMod
        Self.logger.info("gotoMinutesHome, isFromTab = \(isFromTab)")
        let body = MinutesHomePageBody(fromSource: isFromTab ? .meetingTab : .others)
        navigator.push(body: body, from: from)
        #endif
    }

    func gotoSearch(from: UIViewController) {
        #if MessengerMod
        navigator.push(body: SearchMainBody(topPriorityScene: nil, searchTabName: "videochat"), from: from)
        #endif
    }

    /// 聊天页面
    func gotoChat(chatID: String, isGroup: Bool, switchFeedTab: Bool, from: UIViewController) {
        #if MessengerMod
        let from = WindowTopMostFrom(vc: from)
        Self.logger.info("gotoChat: \(chatID), isGroup = \(isGroup), switchFeedTab = \(switchFeedTab)")
        if switchFeedTab {
            navigator.switchTab(Tab.feed.url, from: from, animated: true) { [weak self] _ in
                let context: [String: Any] = [
                    FeedSelection.contextKey: FeedSelection(feedId: chatID, selectionType: .skipSame)
                ]
                if isGroup {
                    self?.navigator.showDetail(body: ChatControllerByIdBody(chatId: chatID),
                                               context: context, wrap: LkNavigationController.self, from: from)
                } else {
                    self?.navigator.showDetail(body: ChatControllerByChatterIdBody(chatterId: chatID, isCrypto: false),
                                               context: context, wrap: LkNavigationController.self, from: from)
                }
            }
        } else {
            if isGroup {
                navigator.push(body: ChatControllerByIdBody(chatId: chatID), from: from)
            } else {
                navigator.push(body: ChatControllerByChatterIdBody(chatterId: chatID, isCrypto: false),
                               from: from)
            }
        }
        #endif
    }

    /// 弹出通话选项的actionSheet
    func showCallsActonSheet(userID: String, name: String, avatarKey: String, isCrossTenant: Bool, from: UIViewController) {
        #if MessengerMod
        Self.logger.info("showCallsActonSheet")
        let callByChannelBody = CallByChannelBody(
            chatterId: userID,
            chatId: nil,
            displayName: name,
            inCryptoChannel: false,
            sender: nil,
            isCrossTenant: isCrossTenant,
            channelType: .unknow,
            isShowVideo: false,
            accessInfo: Chatter.AccessInfo(),
            chatterAvatarKey: avatarKey
        )
        navigator.push(body: callByChannelBody, from: from)
        #endif
    }

    /// 转发消息
    func forwardMessage(_ msg: String, from: UIViewController) {
        #if MessengerMod
        let body = ShareContentBody(title: "", content: msg)
        navigator.present(body: body, from: from, prepare: {
            $0.modalPresentationStyle = .formSheet
        })
        #endif
    }

    func pushOrPresentURL(_ url: URL, from: UIViewController) {
        if LarkUIKit.Display.pad {
            navigator.present(url, context: [:], wrap: LkNavigationController.self, from: from, prepare: { vc in
                vc.modalPresentationStyle = .fullScreen
            }, animated: true, completion: nil)
        } else {
            navigator.push(url, from: from)
        }
    }

    func showEnterpriseCallActionSheet(body: TabPhoneCallBody, from: UIViewController) {
        navigator.present(body: PhoneCallPickerBody(phoneNumber: body.phoneNumber, phoneType: body.phoneType.toPicker()), from: from)
    }

    func startCall(userId: String, isVoiceCall: Bool, from: UIViewController) {
        navigator.present(body: StartMeetingBody(userId: userId, isVoiceCall: isVoiceCall, entrySource: .meetingTab), from: from)
    }

    func startPhoneCall(body: TabPhoneCallBody, from: UIViewController) {
        navigator.present(body: body.toInterface(), from: from)
    }

    func startNewMeeting(from: UIViewController) {
        navigator.present(body: StartMeetingBody(entrySource: .tabTopMeetingNow), from: from)
    }

    func joinMeetingByNumber(from: UIViewController) {
        navigator.present(body: JoinMeetingBody(id: "", idType: .number, entrySource: .tapTopJoinMeeting), from: from)
    }

    func joinMeetingById(_ meetingId: String, topic: String, subtype: MeetingSubType?, from: UIViewController) {
        navigator.present(body: JoinMeetingBody(id: meetingId, idType: .meetingId, entrySource: .meetingTab,
                                                topic: topic, meetingSubtype: subtype?.rawValue),
                          from: from)
    }

    func startShareContent(from: UIViewController) {
        navigator.present(body: ShareContentBody(source: .independTab), from: from)
    }

    func previewParticipantsViewController(body: TabPreviewParticipantsBody) -> UIViewController? {
        let body = PreviewParticipantsBody(participants: body.participants, isPopover: body.isPopover, totalCount: 0, isInterview: body.isInterview, isWebinar: body.isWebinar, selectCellAction: body.selectCellAction)
        return navigator.response(for: body).resource as? UIViewController
    }

    func gotoByteViewSetting(from: UIViewController, completion: (() -> Void)?) {
        guard let setting = try? resolver.resolve(assert: UserSettingManager.self) else {
            return
        }
        let vc = setting.ui.createGeneralSettingViewController(source: "vc_tab")
        navigator.presentOrPush(vc,
                                wrap: LkNavigationController.self,
                                from: from,
                                prepareForPresent: { $0.modalPresentationStyle = .formSheet },
                                completion: { completion?() })
    }

    func push(_ url: URL, context: [String: Any], from: UIViewController, forcePush: Bool, animated: Bool) {
        navigator.push(url, context: context, from: from, forcePush: forcePush, animated: animated)
    }

    /// 会议卡片分享
    func shareMeetingCard(meetingId: String, from: UIViewController, canShare: (() -> Bool)?) {
        #if MessengerMod
        let body = ShareMeetingBody(meetingId: meetingId, skipCopyLink: true, style: .card, source: .tabDetail, canShare: canShare)
        navigator.present(body: body, from: from)
        #endif
    }
}

private extension TabPhoneCallBody.PhoneType {
    func toInterface() -> PhoneCallBody.IdType {
        switch self {
        case .ipPhone:
            return .ipPhone
        case .enterprisePhone:
            return .enterprisePhone
        case .recruitmentPhone:
            return .recruitmentPhone
        }
    }

    func toPicker() -> PhoneCallPickerBody.PhoneType {
        switch self {
        case .ipPhone:
            return .ipPhone
        case .enterprisePhone:
            return .enterprisePhone
        case .recruitmentPhone:
            return .recruitmentPhone
        }
    }
}

private extension TabPhoneCallBody {
    func toInterface() -> PhoneCallBody {
        PhoneCallBody(id: phoneNumber, idType: phoneType.toInterface(), calleeId: calleeId, calleeName: calleeName, calleeAvatarKey: calleeAvatarKey)
    }
}

private final class TabMeetingObserverImpl: TabMeetingObserver, ByteViewInterface.MeetingObserverDelegate {
    let proxy: ByteViewInterface.MeetingObserver?
    let currentMeetingRelay: BehaviorRelay<TabMeeting?>

    init(userResolver: UserResolver) {
        proxy = try? userResolver.resolve(assert: MeetingService.self).createMeetingObserver()
        currentMeetingRelay = BehaviorRelay(value: proxy?.currentMeeting?.toTab())
        proxy?.setDelegate(self)
    }

    func meetingObserver(_ observer: ByteViewInterface.MeetingObserver, meetingChanged meeting: Meeting, oldValue: Meeting?) {
        if meeting.isPending { return }
        let obj = meeting.state == .end ? observer.currentMeeting?.toTab() : meeting.toTab()
        if currentMeetingRelay.value != obj {
            currentMeetingRelay.accept(obj)
        }
    }
}

private extension Meeting {
    func toTab() -> TabMeeting? {
        if isPending || !isActive { return nil }
        return TabMeeting(id: meetingId, isOnTheCall: state == .onTheCall, isInLobby: isInLobby)
    }
}
