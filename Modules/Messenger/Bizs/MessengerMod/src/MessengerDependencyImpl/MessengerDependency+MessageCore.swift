//
//  MessengerMockDependency+MessageCore.swift
//  LarkMessenger
//
//  Created by CharlieSu on 12/3/19.
//

import UIKit
import Foundation
import RxSwift
import EENavigator
import Swinject
import LarkMessageCore
import ServerPB
import LarkModel
import LarkContainer
#if ByteViewMod
import ByteViewInterface
#endif
#if CCMMod
import SpaceInterface
#endif
#if CalendarMod
import Calendar
#endif
#if TodoMod
import TodoInterface
import LarkUIKit
#endif
#if MeegoMod
import LarkMeegoInterface
#endif

public final class MessageCoreDependencyImpl: MessageCoreDependency {
    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func preloadDocFeed(_ url: String, from source: String) {
        #if CCMMod
        (try? resolver.resolve(assert: DocSDKAPI.self))?.preloadDocFeed(url, from: source)
        #endif
    }

    public func downloadThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage> {
        #if CCMMod
        (try? resolver.resolve(assert: DocSDKAPI.self))?.getThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, imageViewSize: imageViewSize) ?? .empty()
        #else
        .empty()
        #endif
    }

    public func notifyEnterChatPage() {
        #if CCMMod
        (try? resolver.resolve(assert: DocSDKAPI.self))?.notifyEnterChatPage()
        #endif
    }

    public func notifyLeaveChatPage() {
        #if CCMMod
        (try? resolver.resolve(assert: DocSDKAPI.self))?.notifyLeaveChatPage()
        #endif
    }

    public func eventTimeDescription(start: Int64, end: Int64, isAllDay: Bool) -> String {
        #if CalendarMod
        (try? resolver.resolve(assert: CalendarInterface.self))?.eventTimeDescription(start: start, end: end, isAllDay: isAllDay) ?? ""
        #else
        ""
        #endif
    }

    public func createTodo(body: MessageCoreTodoBody, from: UIViewController, prepare: @escaping (UIViewController) -> Void, animated: Bool) {
        #if TodoMod
        let fromContent = { () -> TodoInterface.TodoCreateBody.ChatSourceContext.FromContent in
            switch body.fromContent {
            case .chatKeyboard(let arg1):
                return .chatKeyboard(richContent: arg1)
            case .chatSetting:
                return .chatSetting
            case .textMessage(let arg1):
                return .textMessage(richContent: arg1)
            case .postMessage(let arg1, let arg2):
                return .postMessage(title: arg1, richContent: arg2)
            case .threadMessage(let arg1, let arg2, let arg3):
                return .threadMessage(title: arg1, richContent: arg2, threadId: arg3)
            case .mergeForwardMessage(let arg1, let arg2):
                return .mergeForwardMessage(messageId: arg1, chatName: arg2)
            case .multiSelectMessages(let arg1, let arg2):
                return .multiSelectMessages(messageIds: arg1, chatName: arg2)
            case .needsMergeMessage(let arg1, let arg2):
                return .needsMergeMessage(messageId: arg1, title: arg2)
            case .unknownMessage:
                return .unknownMessage
            }
        }()
        var context = TodoCreateBody.ChatSourceContext(
            chatId: body.chatID,
            chatName: body.chatName,
            messageId: body.messageId,
            threadId: body.threadId,
            fromContent: fromContent,
            isThread: body.isThread
        )
        context.atUsers = body.atUsers
        context.extra = body.extra
        context.chatCommonParams = body.chatCommonParams
        resolver.navigator.present(
            body: TodoCreateBody(sourceContext: .chat(context)),
            wrap: LkNavigationController.self,
            from: from,
            prepare: prepare,
            animated: animated
        )
        #endif
    }

    public func createWorkItem(with chat: Chat, messages: [Message]?, sourceVc: UIViewController, from: String) {
        #if MeegoMod
        EntranceSource(rawValue: from)
            .flatMap { (try? resolver.resolve(assert: LarkMeegoService.self))?.createWorkItem( with: chat, messages: messages, sourceVc: sourceVc, from: $0) }
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
