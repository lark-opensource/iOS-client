//
//  AudioContent.swift
//  LarkModel
//
//  Created by chengzhipeng-bytedance on 2018/5/18.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public struct AudioContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message

    // 固有字段
    public let key: String
    public let duration: Int32
    public let size: Int64
    public let voiceText: String
    public let hideVoice2Text: Bool
    public let originSenderID: String
    public let localUploadID: String
    public let originTosKey: String
    public let originSenderName: String
    public let isFriend: Bool
    public var audioSender: Chatter?
    public var isAudioRecognizeFinish: Bool
    public var audio2TextStartTime: TimeInterval
    public var isAudioWithText: Bool
    // 消息链接化场景需要使用previewID做资源鉴权
    public var authToken: String?

    public init(
        key: String,
        duration: Int32,
        size: Int64,
        voiceText: String,
        hideVoice2Text: Bool,
        originSenderID: String,
        localUploadID: String,
        originTosKey: String,
        originSenderName: String,
        isFriend: Bool,
        isAudioRecognizeFinish: Bool,
        audio2TextStartTime: TimeInterval,
        isAudioWithText: Bool) {
        self.key = key
        self.duration = duration
        self.size = size
        self.voiceText = voiceText
        self.hideVoice2Text = hideVoice2Text
        self.originSenderID = originSenderID
        self.localUploadID = localUploadID
        self.originTosKey = originTosKey
        self.originSenderName = originSenderName
        self.isFriend = isFriend
        self.isAudioRecognizeFinish = isAudioRecognizeFinish
        self.audio2TextStartTime = audio2TextStartTime
        self.isAudioWithText = isAudioWithText
    }

    public var showVoiceText: String {
        if hideVoice2Text { return "" }
        return voiceText
    }

    public static func transform(pb: PBModel) -> AudioContent {
        return AudioContent(
            key: pb.content.key,
            duration: pb.content.duration,
            size: pb.content.size,
            voiceText: pb.content.voice2Text,
            hideVoice2Text: pb.content.hideVoice2Text,
            originSenderID: pb.content.originSenderIDStr,
            localUploadID: pb.content.localUploadID,
            originTosKey: pb.content.originTosKey,
            originSenderName: pb.content.originSenderName,
            isFriend: pb.content.isFriend,
            isAudioRecognizeFinish: pb.content.isAudioRecognizeFinish,
            audio2TextStartTime: TimeInterval(pb.content.audio2TextStartTime),
            isAudioWithText: pb.content.isAudioWithText
        )
    }

    public static func transform(pb: Basic_V1_TranslateInfo) -> AudioContent {
        return AudioContent(
            key: pb.content.key,
            duration: pb.content.duration,
            size: pb.content.size,
            voiceText: pb.content.voice2Text,
            hideVoice2Text: pb.content.hideVoice2Text,
            originSenderID: pb.content.originSenderIDStr,
            localUploadID: pb.content.localUploadID,
            originTosKey: pb.content.originTosKey,
            originSenderName: pb.content.originSenderName,
            isFriend: pb.content.isFriend,
            isAudioRecognizeFinish: pb.content.isAudioRecognizeFinish,
            audio2TextStartTime: TimeInterval(pb.content.audio2TextStartTime),
            isAudioWithText: pb.content.isAudioWithText
        )
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if let translatePB = entity.translateMessages[message.id] {
            message.translateState = .translated
            message.atomicExtra.unsafeValue.translateContent = AudioContent.transform(pb: translatePB)
        }
        self.audioSender = try? Chatter.transformChatChatter(
            entity: entity,
            chatID: message.channel.id,
            id: originSenderID
        )
    }

    public mutating func complement(previewID: String, messageLink: Basic_V1_MessageLink, message: Message) {
        self.authToken = previewID
    }
}
