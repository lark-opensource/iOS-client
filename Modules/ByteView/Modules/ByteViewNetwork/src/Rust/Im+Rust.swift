//
//  Im+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

typealias PBVideoChatInteractionMessage = Videoconference_V1_VideoChatInteractionMessage
typealias PBVideoChatParticipant = Videoconference_V1_VideoChatParticipant
typealias PBTranslateInfo = Videoconference_V1_VCTranslateInfo
typealias PBTranslateLanguagesConfiguration = Im_V1_LanguagesConfiguration
typealias PBEmojiPanel = Im_V1_EmojiPanel

extension PBVideoChatInteractionMessage {
    var vcType: VideoChatInteractionMessage {
        .init(id: id, type: .init(rawValue: type.rawValue) ?? .unknown, meetingID: meetingID,
              content: content?.vcType, fromUser: fromUser.vcType, tenantID: tenantID, cid: cid,
              position: position, createMilliTime: createMilliTime,
              tags: tags.map({ .init(rawValue: $0.rawValue) ?? .unknown }))
    }
}

extension PBVideoChatInteractionMessage.OneOf_Content {
    var vcType: VideoChatInteractionMessageContent? {
        switch self {
        case .textContent(let v):
            return .textContent(.init(content: v.content))
        case .systemContent(let v):
            return .systemContent(.init(type: .init(rawValue: v.type.rawValue) ?? .unknown))
        case .reactionContent(let v):
            return .reactionContent(.init(content: v.content, count: Int(v.count)))
        case .encryptedContent(let v):
            return .encryptedContent(.init(content: v.content))
        @unknown default:
            return nil
        }
    }
}

extension PBVideoChatParticipant {
    var vcType: VideoChatParticipant {
        .init(userID: userID, type: type.vcType, deviceID: deviceID, name: name, avatarKey: avatarKey,
              role: .init(rawValue: role.rawValue) ?? .unknown, isBot: isBot)
    }
}

extension PBTranslateInfo {
    var vcType: TranslateInfo {
        .init(containerID: containerID, messageID: messageID, language: language,
              errCode: .init(rawValue: errCode.rawValue) ?? .unknown,
              translateSource: .init(rawValue: translateSource.rawValue) ?? .unknown,
              displayRule: .init(rawValue: displayRule.rawValue) ?? .unknown,
              displayArea: .init(rawValue: displayArea.rawValue) ?? .chatbox,
              messageType: .init(rawValue: messageType.rawValue) ?? .unknown,
              content: content?.vcType)
    }
}

extension PBTranslateInfo.OneOf_Content {
    var vcType: VideoChatInteractionMessageContent? {
        switch self {
        case .textContent(let v):
            return .textContent(.init(content: v.content))
        case .systemContent(let v):
            return .systemContent(.init(type: .init(rawValue: v.type.rawValue) ?? .unknown))
        case .reactionContent(let v):
            return .reactionContent(.init(content: v.content, count: Int(v.count)))
        @unknown default:
            return nil
        }
    }
}

extension PBTranslateLanguagesConfiguration {
    var vcType: TranslateLanguagesConfiguration {
        .init(rule: .init(rawValue: rule.rawValue) ?? .unknown)
    }
}

extension PBEmojiPanel.Emojis.EmojiKey {
    var vcType: EmojiPanel.Emojis.EmojiKey {
        EmojiPanel.Emojis.EmojiKey(key: key, selectedSkinKey: selectedSkinKey)
    }
}

extension PBEmojiPanel.Emojis {
    var vcType: EmojiPanel.Emojis {
        EmojiPanel.Emojis(type: EmojiPanel.EmojiPanelType(rawValue: type.rawValue) ?? .unknown,
                          iconKey: iconKey,
                          title: title,
                          source: source,
                          keys: keys.map { $0.vcType })
    }
}

extension PBEmojiPanel {
    var vcType: EmojiPanel {
        EmojiPanel(emojisOrder: emojisOrder.map { $0.vcType })
    }
}
