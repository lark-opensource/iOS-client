//
//  MeetingBasicService.swift
//  ByteView
//
//  Created by kiri on 2023/2/16.
//

import Foundation
import ByteViewMeeting
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting
import ByteViewRtcBridge
import LarkShortcut
import EEAtomic

typealias UserStorage = TypedLocalStorage<UserStorageKey>

/// 会议所依赖的基础服务，包含账号/网络请求/网络推送/外部页面跳转/设置（end state后不可用）
final class MeetingBasicService {
    private let session: MeetingSession
    var sessionId: String { session.sessionId }
    var meetingId: String { session.meetingId }
    var breakoutRoomId: String? { setting.breakoutRoomId }
    private let dependency: MeetingDependency
    init(session: MeetingSession, dependency: MeetingDependency) {
        self.session = session
        self.dependency = dependency
        self._setting = SafeLazy {
            MeetingSettingManager(sessionId: session.sessionId, service: dependency.setting)
        }
    }

    var accountInfo: AccountInfo { dependency.account }
    var userId: String { accountInfo.userId }
    var httpClient: HttpClient { dependency.httpClient }

    private(set) lazy var account = accountInfo.user
    // try fix https://t.wtturl.cn/i8aHKpKe/
    @SafeLazy var setting: MeetingSettingManager
    private(set) lazy var larkRouter = LarkRouter(dependency: dependency.router)
    private(set) lazy var push = MeetingPushCenter(session: session)
    private(set) lazy var router = Router(session: session, dependency: dependency)
    private(set) lazy var storage = dependency.storage.toStorage(UserStorageKey.self)
    private(set) lazy var security = MeetingSecurityControl(security: dependency.lark.security)

    var larkUtil: LarkDependency { dependency.lark }
    var calendar: CalendarDependency { dependency.calendar }
    var messenger: MessengerDependency { dependency.messenger }
    var minutes: MinutesDependency { dependency.minutes }
    var live: LiveDependency { dependency.live }
    var ccm: CCMDependency { dependency.ccm }
    var emotion: EmotionDependency { dependency.lark.emotion }
    var emojiData: EmojiDataDependency { dependency.lark.emojiData }
    var heimdallr: HeimdallrDependency { dependency.heimdallr }
    var shortcut: ShortcutService? { dependency.shortcut }
    private(set) lazy var perfMonitor = dependency.perfMonitor
    private(set) lazy var myAI = MeetingMyAI(dependency: dependency.myAI)

    @RwAtomic private var _rtc: MeetingRtcEngine?
    var rtc: MeetingRtcEngine {
        createRtcIfNeeded(.init(session: session, setting: setting))
    }

    func prestartRtc(_ params: RtcCreateParams) {
        createRtcIfNeeded(params).prestart(params)
    }

    func startRtcForEffect() {
        self.rtc.startForEffect()
    }

    func releaseRtc(completion: (() -> Void)? = nil) {
        if let rtc = _rtc {
            rtc.release(completion: completion)
        } else {
            completion?()
        }
    }

    @discardableResult
    private func createRtcIfNeeded(_ params: @autoclosure () -> RtcCreateParams) -> MeetingRtcEngine {
        if let rtc = _rtc {
            return rtc
        } else {
            let rtc = MeetingRtcEngine(createParams: params())
            _rtc = rtc
            return rtc
        }
    }

    func currentMeetingDependency() -> MeetingDependency {
        return dependency
    }

    func postMeetingChanges(_ changes: (inout MeetingObserver.Meeting) -> Void) {
        MeetingObserverCenter.shared.postChanges(for: self.sessionId, action: changes)
    }
}

extension MeetingBasicService {
    func shouldShowGuide(_ key: GuideKey) -> Bool {
        larkUtil.shouldShowGuide(key: key.rawValue)
    }

    func didShowGuide(_ key: GuideKey) {
        larkUtil.didShowGuide(key: key.rawValue)
    }
}

protocol MeetingBasicServiceProvider {
    var service: MeetingBasicService { get }
}

extension MeetingBasicServiceProvider {
    var meetingId: String { service.meetingId }
    var sessionId: String { service.sessionId }
    var breakoutRoomId: String? { service.breakoutRoomId }
    var account: ByteviewUser { service.account }
    var setting: MeetingSettingManager { service.setting }
    var httpClient: HttpClient { service.httpClient }
    var larkRouter: LarkRouter { service.larkRouter }
    var push: MeetingPushCenter { service.push }
    var router: Router { service.router }
    var storage: UserStorage { service.storage }
    var security: MeetingSecurityControl { service.security }
    var shortcut: ShortcutService? { service.shortcut }
}

extension ShortcutActionContext {
    func isValid(for session: MeetingSession) -> Bool {
        if let sessionId = string("sessionId") {
            return sessionId == session.sessionId
        }
        if let meetingId = string("meetingId") {
            return meetingId == session.meetingId
        }
        return false
    }

    func isValid(for service: MeetingBasicServiceProvider) -> Bool {
        if let sessionId = string("sessionId") {
            return sessionId == service.sessionId
        }
        if let meetingId = string("meetingId") {
            return meetingId == service.meetingId
        }
        return false
    }
}
