//
//  ByteViewDependencies.swift
//  ByteViewDependency
//
//  Created by kiri on 2021/7/1.
//

import Foundation
import UIKit
import ByteViewCommon
import ByteViewSetting
import ByteViewNetwork
import RxRelay

public protocol TabDependency {
    var global: TabGlobalDependency { get }
    var router: TabRouteDependency? { get }
    var badgeService: TabBadgeService? { get }
    var accountInfo: AccountInfo { get }
    var setting: UserSettingManager { get }
    var httpClient: HttpClient { get }

    var docsIconDependency: TabDocsIconDependency { get }

    func fg(_ key: String) -> Bool

    func setPasteboardText(_ message: String, token: String, shouldImmunity: Bool) -> Bool
    func getPasteboardText(token: String) -> String?

    /// guide key 需要由 PM 申请
    func shouldShowGuide(key: String) -> Bool
    /// guide key 需要由 PM 申请
    func didShowGuide(key: String)

    var currentMeeting: TabMeeting? { get }
    func createMeetingObserver() -> TabMeetingObserver
}

public protocol TabGlobalDependency {
    /// split模式
    func splitDisplayMode(for vc: UIViewController) -> SplitDisplayMode?

    /// 会议tab是否被选中
    func isByteViewTabSelected(for vc: UIViewController) -> Bool

    /// 主window
    var mainSceneWindow: UIWindow? { get }

    /// 生成循环日程描述
    func formatRRuleString(rrule: String, userId: String) -> String

    /// 是否24小时制
    var is24HourTime: Bool { get }

    /// 格式化日程时间
    func formatCalendarDateTimeRange(startTime: TimeInterval, endTime: TimeInterval) -> String
}

public protocol TabDocsIconDependency {
    ///异步获取icon图片
    ///支持通过url进行兜底显示
    func getDocsIconImageAsync(url: String, finish: @escaping (UIImage) -> Void)
}

public protocol TabRouteDependency {

    /// 日程详情
    func gotoCalendarEvent(calendarID: String, key: String, originalTime: Int, startTime: Int, from: UIViewController)

    /// 创建日程
    func gotoCreateCalendarEvent(title: String?, startDate: Date, endDate: Date?, isAllDay: Bool, timeZone: TimeZone, from: UIViewController)

    /// 创建Webinar日程
    func gotoCreateWebinarCalendarEvent(title: String?, startDate: Date, endDate: Date?, isAllDay: Bool, timeZone: TimeZone, from: UIViewController)

    /// 个人信息
    func gotoUserProfile(userId: String, meetingTopic: String, sponsorName: String, sponsorId: String, meetingId: String,
                         from: UIViewController)

    /// 切换至日历tab首页
    func gotoCalendarTab(from: UIViewController)

    /// 跳转到MM
    func gotoMinutesHome(from: UIViewController, isFromTab: Bool)

    /// 聊天页面
    func gotoChat(chatID: String, isGroup: Bool, switchFeedTab: Bool, from: UIViewController)

    func gotoSearch(from: UIViewController)

    /// 弹出通话选项的actionSheet
    func showCallsActonSheet(userID: String, name: String, avatarKey: String, isCrossTenant: Bool, from: UIViewController)

    /// 转发消息
    func forwardMessage(_ msg: String, from: UIViewController)

    /// iPad上present，iPhone上push
    func pushOrPresentURL(_ url: URL, from: UIViewController)

    func showEnterpriseCallActionSheet(body: TabPhoneCallBody, from: UIViewController)

    func startCall(userId: String, isVoiceCall: Bool, from: UIViewController)

    func startPhoneCall(body: TabPhoneCallBody, from: UIViewController)

    func startNewMeeting(from: UIViewController)

    func startShareContent(from: UIViewController)

    func joinMeetingByNumber(from: UIViewController)

    func joinMeetingById(_ meetingId: String, topic: String, subtype: MeetingSubType?, from: UIViewController)

    func previewParticipantsViewController(body: TabPreviewParticipantsBody) -> UIViewController?

    func gotoByteViewSetting(from: UIViewController, completion: (() -> Void)?)

    func push(_ url: URL, context: [String: Any], from: UIViewController, forcePush: Bool, animated: Bool)

    /// 会议卡片分享
    func shareMeetingCard(meetingId: String, from: UIViewController, canShare: (() -> Bool)?)
}

/// SplitViewController展示样式
public enum SplitDisplayMode: Int {
    /// 自动状态，不是真实的展示样式，会根据系统的CR变化通知，在C视图下展示masterAndDetail，在R视图下展示allVisible
    case automatic

    /// 双栏展示，master在左边，detail在右边
    case allVisible

    /// 其他模式，暂时对ByteViewTab无用
    case other
}

public struct TabPhoneCallBody {
    public let phoneNumber: String
    public let phoneType: PhoneType

    public var calleeId: String?
    public var calleeName: String?
    public var calleeAvatarKey: String?

    public enum PhoneType {
        case ipPhone
        case recruitmentPhone
        case enterprisePhone
    }
}

public struct TabPreviewParticipantsBody {
    public var participants: [PreviewParticipant]
    public var isPopover: Bool
    public var isInterview: Bool
    public var isWebinar: Bool
    public var selectCellAction: ((PreviewParticipant, UIViewController) -> Void)?
}

public protocol TabMeetingObserver {
    var currentMeetingRelay: BehaviorRelay<TabMeeting?> { get }
}

extension TabMeetingObserver {
    var currentMeeting: TabMeeting? { currentMeetingRelay.value }
}

/// 仅表示currentMeeting
public struct TabMeeting: Equatable {
    public let id: String
    public let isOnTheCall: Bool
    public let isInLobby: Bool

    public init(id: String, isOnTheCall: Bool, isInLobby: Bool) {
        self.id = id
        self.isOnTheCall = isOnTheCall
        self.isInLobby = isInLobby
    }
}
