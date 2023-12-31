//
//  NotificationExtra.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public struct Extra: JSONCodable {
    public let type: PushType
    public var content: PushContent
    public let pushAction: PushAction

    public init(type: PushType,
                content: PushContent,
                pushAction: PushAction = .noticeImmediatly) {
        self.type = type
        self.content = content
        self.pushAction = pushAction
    }

    //swiftlint:disable cyclomatic_complexity
    public init?(dict: [String: Any]) {
        guard let type = dict["type"] as? Int,
            let contentDict = dict["content"] as? [String: Any] else {
            return nil
        }
        self.type = PushType(rawValue: type) ?? .unknow
        var content: PushContent?
        switch self.type {
        case .unknow:
            content = UnknowContent()
        case .badge:
            content = BadgeContent(dict: contentDict)
        case .active:
            content = ActiveContent(dict: contentDict)
        case .call:
            content = CallContent(dict: contentDict)
        case .video:
            content = VideoContent(dict: contentDict)
        case .calendar:
            content = CalendarContent(dict: contentDict)
        case .todo:
            content = TodoPushContent(dict: contentDict)
        case .docs:
            content = DocsContent(dict: contentDict)
        case .message:
            content = MessageContent(dict: contentDict)
        case .reaction:
            content = ReactionContent(dict: contentDict)
        case .urgent:
            content = UrgentContent(dict: contentDict)
        case .urgentAck:
            content = UrgentAckContent(dict: contentDict)
        case .chatApplication:
            content = ChatApplicationContent(dict: contentDict)
        case .mail:
            content = MailContent(dict: contentDict)
        case .chatApply:
            content = ChatApplyContent(dict: contentDict)
        case .openApp:
            content = OpenAppContent(dict: contentDict)
        case .openAppChat:
            content = OpenAppChatContent(dict: contentDict)
        case .openMicroApp:
            content = OpenMicroAppContent(dict: contentDict)
        }

        if let pushAction = dict["pushAction"] as? Int {
            self.pushAction = PushAction(rawValue: pushAction) ?? .noticeImmediatly
        } else {
            self.pushAction = .noticeImmediatly
        }

        if let content = content {
            self.content = content
        } else {
            return nil
        }
    }
    //swiftlint:enable cyclomatic_complexity

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["type"] = self.type.rawValue
        dict["pushAction"] = self.pushAction.rawValue
        dict["content"] = self.content.toDict()

        return dict
    }
}
