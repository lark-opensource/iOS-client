//
//  ChatDependency.swift
//  LarkChat
//
//  Created by 李晨 on 2019/11/27.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkMessengerInterface
import LarkCore
import LarkKeyboardView
import RxRelay
import ServerPB
import RustPB
import LarkOpenChat
import LarkAccountInterface
import LarkUIKit
import LarkFeatureGating
import LarkMessageCore
import EENavigator

public typealias ChatDependency = ChatDocDependency & ChatCalendarDependency
    & ChatByteViewDependency & ChatMicroAppDependency
    & ChatTodoDependency & ChatCellViewModelFactoryDependency
    & ChatMessageCellVMDependency & ChatWAContainerDependency

public struct MessengerSendDocModel {
    public let url: String
    public init(url: String) { self.url = url }
}

public typealias SendDocBlock = (Bool, [MessengerSendDocModel]) -> Void

public protocol ChatDocDependency {
    func preloadDocFeed(_ url: String, from: String)
    func isSupportURLType(url: URL) -> (Bool, type: String, token: String)

    func presentTabSendDocController(chat: Chat, title: String, presentParam: PresentParam, chatOpenTabService: ChatOpenTabService)
    func createDocsByTemplate(docToken: String, docType: Int, templateId: String, result: (((url: String?, title: String?), Error?) -> Void)?)
}

public protocol ChatWAContainerDependency {
    func preloadWebAppIfNeed(appId: String)
}

public protocol ChatMeetingCard {
    var closeMeetingAction: (() -> Void)? { get set }
    var tapMeetingAction: (() -> Void)? { get set }
    var closeTransferAction: (() -> Void)? { get set }
    var isOrganizer: Bool { get }
    var isEventReady: Bool { get }
    var instanceStartTime: TimeInterval { get }
    var instanceEndTime: TimeInterval { get }
}

public protocol ChatCalendarDependency {
    func eventTimeDescription(start: Int64, end: Int64, isAllDay: Bool) -> String
}

extension ChatCalendarDependency {
}

/// 日程参与人
public enum Attendee {
    case p2p(chatId: String, chatterId: String)
    case partialGroupMembers(chatId: String, memberChatterIds: [String])
    case partialMeetingGroupMembers(chatId: String, memberChatterIds: [String])
}

public enum CallClickSource: String {
    case addressBookCard
    case rightUpCornerButton
}

public protocol ChatTodoDependency {
    /// url 是否是任务清单 AppLink
    func isTaskListAppLink(_ url: URL) -> Bool
}

public protocol ChatByteViewDependency {
    var meetingEnable: Bool { get }

    func pushStartSingleMeetingVC(userID: String, secureChatID: String, isVoiceCall: Bool, pushParam: PushParam)

    func pushJoinMeetingVC(groupID: String, isFromSecretChat: Bool, isE2Ee: Bool, isJoinMeeting: Bool, pushParam: PushParam)

    func isRinging() -> Bool
    func hasCurrentModule() -> Bool
    func inRingingCannotCallVoIPText() -> String
    func isInCallText() -> String

    func start(userId: String, source: CallClickSource, secureChatId: String, isVoiceCall: Bool, isE2Ee: Bool, fail: ((CollaborationError?) -> Void)?)

    var isCompanyCallEnabled: Bool { get }
    func startCompanyCall(calleeUserId: String, calleeName: String, calleeAvatarKey: String, chatId: String)

    var serviceCallName: String { get }
    var serviceCallIcon: UIImage { get }

    var meetingWindowInfoOb: Observable<ChatByteViewMeetingWindowInfo> { get }
    func getAssociatedMeeting(groupId: String) -> Observable<String?>
}

public struct ChatByteViewMeetingWindowInfo: Equatable {
    /// 是否存在会议window
    public let hasWindow: Bool
    /// 是否小窗
    public let isFloating: Bool

    private weak var _windowScene: AnyObject?
    /// 会议窗口所在的scene
    @available(iOS 13.0, *)
    public var windowScene: UIWindowScene? {
        get { _windowScene as? UIWindowScene }
        set { _windowScene = newValue }
    }

    public init(hasWindow: Bool, isFloating: Bool) {
        self.isFloating = isFloating
        self.hasWindow = hasWindow
    }

    public static func == (lhs: ChatByteViewMeetingWindowInfo, rhs: ChatByteViewMeetingWindowInfo) -> Bool {
        lhs.hasWindow == rhs.hasWindow && lhs.isFloating == rhs.isFloating && lhs._windowScene === rhs._windowScene
    }
}

extension ChatByteViewDependency {
    func pushStartSingleMeetingVC(
        navigator: Navigatable,
        userMeta: CollaborationUserMeta,
        isVoiceCall: Bool,
        pushParam: PushParam
    ) {
        self.start(userId: userMeta.chatterId,
                   source: .rightUpCornerButton,
                   secureChatId: userMeta.chatId,
                   isVoiceCall: isVoiceCall,
                   isE2Ee: false) { error in
            CollaborationErrorManager.processPushStartSingleMeetingVCError(navigator: navigator, meta: userMeta, error: error, from: pushParam.from)
        }
    }
}
