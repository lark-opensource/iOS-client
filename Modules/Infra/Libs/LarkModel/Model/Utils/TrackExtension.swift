//
//  TrackExtension.swift
//  Pods
//
//  Created by kongkaikai on 2019/7/26.
//

import Foundation
import RustPB

extension Message {
    public var trackAtType: String {
        var atType = "other"
        if isAtAll {
            atType = "atall"
        } else if isAtMe {
            atType = "atme"
        } else {
            atType = "none"
        }
        return atType
    }
}

extension Message.TypeEnum {
    public var trackValue: String {
        var messageType: String = "other"
        switch self {
        case .post:
            messageType = "richtext"
        case .file:
            messageType = "file"
        case .folder:
            messageType = "folder"
        case .text:
            messageType = "text"
        case .image:
            messageType = "image"
        case .system:
            messageType = "system"
        case .audio:
            messageType = "voice"
        case .email:
            messageType = "mail"
        case .shareGroupChat:
            messageType = "shareGroupChat"
        case .sticker:
            messageType = "sticker"
        case .unknown:
            messageType = "other"
        case .shareUserCard:
            messageType = "namecard"
        case .calendar, .generalCalendar:
            messageType = "calendar"
        case .mergeForward:
            messageType = "mergeForward"
        case .card:
            messageType = "card"
        case .media:
            messageType = "video"
        case .shareCalendarEvent:
            messageType = "shareCalendarEvent"
        case .hongbao, .commercializedHongbao:
            messageType = "hongbao"
        case .videoChat:
            messageType = "videoChat"
        case .location:
            messageType = "location"
        case .todo:
            messageType = "todo"
        case .vote:
            messageType = "vote"
        case .diagnose:
            messageType = "diagnose"
        @unknown default:
            assert(false, "new value")
            messageType = "unknown"
        }
        return messageType
    }
}

extension Chat {
    public var trackType: String {
        if chatMode == .threadV2 {
            return "group_topic"
        }
        if isMeeting {
            return "meeting"
        } else {
            if chatter?.type == .bot {
                return "single_bot"
            }
            switch type {
            case .group:
                return "group"
            case .p2P:
                return "single"
            case .topicGroup:
                return "topicGroup"
            @unknown default:
                assert(false, "new value")
                return "unknown"
            }
        }
    }

    public var trackTypeInfo: [String: String] {
        let isBot = type == .p2P && chatter?.type == .bot
        var params = [String: String]()
        params["is_bot_chat"] = isBot ? "true" : "false"
        params["is_meeting_chat"] = isMeeting ? "true" : "false"
        return params
    }
}
