//
//  MessengerMockDependency+Chat.swift
//  LarkMessenger
//
//  Created by CharlieSu on 12/3/19.
//

import UIKit
import Foundation
import RxSwift
import Swinject
import LarkMessengerInterface
import LarkModel
import EENavigator
import LarkChat
import LarkChatSetting
import LarkCore
import LarkKeyboardView
import LarkUIKit
import RxRelay
import RustPB
import ServerPB
import LarkFoundation
import LarkOpenChat
import LarkContainer
#if CalendarMod
import Calendar
#endif
#if ByteViewMod
import ByteViewInterface
#endif
#if CCMMod
import CCMMod
import SpaceInterface
#endif
#if GagetMod
import LarkOPInterface
#endif
#if TodoMod
import TodoInterface
#endif
#if MeegoMod
import LarkMeegoInterface
#endif

public final class ChatDependencyImpl: ChatDependency {
    private let resolver: UserResolver
    private let disposeBag: DisposeBag = DisposeBag()

    private lazy var meetingWindowInfoPublishSubject: PublishSubject<ChatByteViewMeetingWindowInfo> = PublishSubject()
    private lazy var meetingWindowInfoRelay: BehaviorRelay<ChatByteViewMeetingWindowInfo> = {
        #if ByteViewMod
        self.meetingObserver = meetingService?.createMeetingObserver()
        guard let service = self.meetingObserver else {
            return BehaviorRelay<ChatByteViewMeetingWindowInfo>(value: ChatByteViewMeetingWindowInfo(hasWindow: false, isFloating: false))
        }
        service.setDelegate(self)
        let infoRelay = BehaviorRelay<ChatByteViewMeetingWindowInfo>(value: ChatByteViewMeetingWindowInfo(service.currentMeeting?.windowInfo))
        self.meetingWindowInfoPublishSubject
            .asObservable()
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { info in
                if infoRelay.value != info {
                    infoRelay.accept(info)
                }
            }).disposed(by: disposeBag)
        return infoRelay
        #else
        return BehaviorRelay<ChatByteViewMeetingWindowInfo>(value: ChatByteViewMeetingWindowInfo(hasWindow: false, isFloating: false))
        #endif
    }()

    public var meetingWindowInfoOb: Observable<ChatByteViewMeetingWindowInfo> {
        return meetingWindowInfoRelay.asObservable()
    }

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    #if ByteViewMod
    private var meetingService: MeetingService? {
        try? resolver.resolve(assert: MeetingService.self)
    }
    private var meetingObserver: MeetingObserver?
    #endif

    public var meetingEnable: Bool {
        #if ByteViewMod
        meetingService != nil
        #else
        false
        #endif
    }

    public func pushStartSingleMeetingVC(userID: String, secureChatID: String, isVoiceCall: Bool, pushParam: PushParam) {
        #if ByteViewMod
        let body = StartMeetingBody(userId: userID, secureChatId: secureChatID, isVoiceCall: isVoiceCall, entrySource: .chatWindowBanner)
        resolver.navigator.push(body: body, pushParam: pushParam)
        #endif
    }

    public func pushJoinMeetingVC(groupID: String, isFromSecretChat: Bool, isE2Ee: Bool, isJoinMeeting: Bool, pushParam: PushParam) {
        #if ByteViewMod
        let body = JoinMeetingBody(id: groupID, idType: .group, isFromSecretChat: isFromSecretChat,
                                   isE2Ee: isJoinMeeting ? isFromSecretChat : isE2Ee, isStartMeeting: !isJoinMeeting,
                                   entrySource: .chatWindowBanner)
        resolver.navigator.push(body: body, pushParam: pushParam)
        #endif
    }

    public func getAssociatedMeeting(groupId: String) -> Observable<String?> {
        #if ByteViewMod
        Observable.create { [weak self] ob in
            guard let self = self, let service = try? self.resolver.resolve(type: MeetingService.self) else {
                ob.onCompleted()
                return Disposables.create()
            }

            service.getAssociatedMeeting(groupId: groupId) { result in
                switch result {
                case .success(let meetingId):
                    ob.onNext(meetingId)
                case .failure(let error):
                    ob.onError(error)
                }
            }
            return Disposables.create()
        }
        #else
        .empty()
        #endif
    }

    public func isRinging() -> Bool {
        #if ByteViewMod
        (try? resolver.resolve(assert: MeetingService.self))?.currentMeeting?.state == .ringing
        #else
        false
        #endif
    }

    public func hasCurrentModule() -> Bool {
        #if ByteViewMod
        (try? resolver.resolve(assert: MeetingService.self))?.currentMeeting?.isActive == true
        #else
        false
        #endif
    }

    public func inRingingCannotCallVoIPText() -> String {
        #if ByteViewMod
        meetingService?.resources.inRingingCannotCallVoIP ?? ""
        #else
        ""
        #endif
    }

    public func isInCallText() -> String {
        #if ByteViewMod
        meetingService?.resources.isInCallText ?? ""
        #else
        ""
        #endif
    }

    public func start(userId: String, source: LarkChat.CallClickSource, secureChatId: String, isVoiceCall: Bool, isE2Ee: Bool, fail: ((CollaborationError?) -> Void)?) {
        #if ByteViewMod
        let fromVC = resolver.navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        let byteViewSource: VCMeetingEntry
        switch source {
        case .addressBookCard:
            byteViewSource = .addressBookCard
        case .rightUpCornerButton:
            byteViewSource = .rightUpCornerButton
        }
        let body = StartMeetingBody(userId: userId, secureChatId: secureChatId, isVoiceCall: isVoiceCall, entrySource: byteViewSource, isE2Ee: isE2Ee)
        var context: [String: Any] = [:]
        if let fail = fail {
            let failure: (MeetingError?) -> Void = { (vcError) in
                var error: CollaborationError?
                if let vcError = vcError {
                    switch vcError {
                    case .collaborationBlocked:
                        error = .collaborationBlocked
                    case .collaborationBeBlocked:
                        error = .collaborationBeBlocked
                    case .collaborationNoRights:
                        error = .collaborationNoRights
                    default:
                        error = .otherError
                    }
                }
                fail(error)
            }
            context["fail"] = failure
        }
        resolver.navigator.push(body: body, context: context, from: fromVC)
        #endif
    }

    public func startCompanyCall(calleeUserId: String, calleeName: String, calleeAvatarKey: String, chatId: String) {
        #if ByteViewMod
        let fromVC = resolver.navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        let body = PhoneCallBody(id: chatId, idType: .chatId, calleeId: calleeUserId, calleeName: calleeName, calleeAvatarKey: calleeAvatarKey)
        resolver.navigator.push(body: body, from: fromVC)
        #endif
    }

    public var serviceCallName: String {
        #if ByteViewMod
        meetingService?.resources.serviceCallName ?? ""
        #else
        ""
        #endif
    }

    public var serviceCallIcon: UIImage {
        #if ByteViewMod
        meetingService?.resources.serviceCallIcon ?? UIImage()
        #else
        UIImage()
        #endif
    }

    public var isCompanyCallEnabled: Bool {
        #if ByteViewMod
        meetingService?.isCompanyCallEnabled ?? false
        #else
        false
        #endif
    }

    public func eventTimeDescription(start: Int64, end: Int64, isAllDay: Bool) -> String {
        #if CalendarMod
        (try? resolver.resolve(assert: CalendarInterface.self))?.eventTimeDescription(start: start, end: end, isAllDay: isAllDay) ?? ""
        #else
        ""
        #endif
    }

    public func preloadDocFeed(_ url: String, from source: String) {
        #if CCMMod
        (try? resolver.resolve(assert: DocSDKAPI.self))?.preloadDocFeed(url, from: source)
        #endif
    }

    public func preloadWebAppIfNeed(appId: String) {
        #if CCMMod
        _ = (try? resolver.resolve(assert: WebAppSDK.self))?.preload(appId: appId)
        #endif
    }

    public func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
        #if CCMMod
        (try? resolver.resolve(assert: DocSDKAPI.self))?.isSupportURLType(url: url) ?? (false, "", "")
        #else
        (false, "", "")
        #endif
    }

    public func presentTabSendDocController(chat: Chat, title: String, presentParam: PresentParam, chatOpenTabService: ChatOpenTabService) {
        #if CCMMod
        let body = SendDocBody(SendDocBody.Context(title: title,
                                                   chat: chat,
                                                   sendDocCanSelectType: .sendDocNotOptionalType,
                                                   chatOpenTabService: chatOpenTabService)) { _, _ in }
        resolver.navigator.present(body: body, presentParam: presentParam)
        #endif
    }

    public func createDocsByTemplate(docToken: String, docType: Int, templateId: String, result: (((url: String?, title: String?), Error?) -> Void)?) {
        #if CCMMod
        (try? resolver.resolve(assert: DocsTemplateCreateProtocol.self))?.createDocsByTemplate(
            docToken: docToken,
            docType: docType,
            templateId: templateId,
            result: { createResult, error in
                result?((url: createResult?.url, title: createResult?.title), error)
            })
        #endif
    }

    public func takeMessageActionV2(chatId: String, messageIds: [String], isMultiSelect: Bool, targetVC: UIViewController) {
        #if GagetMod
        (try? resolver.resolve(assert: OpenPlatformService.self))?.takeMessageActionV2(chatId: chatId, messageIds: messageIds, isMultiSelect: isMultiSelect, targetVC: targetVC)
        #endif
    }

    public func isTaskListAppLink(_ url: URL) -> Bool {
        #if TodoMod
        (try? resolver.resolve(assert: TodoService.self))?.isTaskListAppLink(url) ?? false
        #else
        false
        #endif
    }

    public func canDisplayCreateWorkItemEntrance(chat: Chat, from: String) -> Bool {
        #if MeegoMod
        if let fromEnum = EntranceSource(rawValue: from) {
            return (try? resolver.resolve(assert: LarkMeegoService.self))?.canDisplayCreateWorkItemEntrance(chat: chat, from: fromEnum) ?? false
        }
        return false
        #else
        false
        #endif
    }

    public func canDisplayCreateWorkItemEntrance(chat: Chat, messages: [Message]?, from: String) -> Bool {
        #if MeegoMod
        if let fromEnum = EntranceSource(rawValue: from) {
            return (try? resolver.resolve(assert: LarkMeegoService.self))?.canDisplayCreateWorkItemEntrance(chat: chat, messages: messages, from: fromEnum) ?? false
        }
        return false
        #else
        false
        #endif
    }
}

#if ByteViewMod
extension ChatDependencyImpl: MeetingObserverDelegate {
    public func meetingObserver(_ observer: MeetingObserver, meetingChanged meeting: Meeting, oldValue: Meeting?) {
        if meeting.isPending { return }
        let currentMeeting = meeting.state == .end ? observer.currentMeeting : meeting
        let chatWindowInfo = ChatByteViewMeetingWindowInfo(currentMeeting?.windowInfo)
        meetingWindowInfoPublishSubject.onNext(chatWindowInfo)
    }
}

private extension ChatByteViewMeetingWindowInfo {
    init(_ windowInfo: MeetingWindowInfo?) {
        if let info = windowInfo {
            self.init(hasWindow: info.hasWindow, isFloating: info.isFloating)
            if #available(iOS 13.0, *) {
                self.windowScene = info.windowScene
            }
        } else {
            self.init(hasWindow: false, isFloating: false)
        }
    }
}
#endif
