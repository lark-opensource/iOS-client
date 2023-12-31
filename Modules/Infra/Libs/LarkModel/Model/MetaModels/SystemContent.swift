//
//  SystemContent.swift
//  LarkModel
//
//  Created by chengzhipeng-bytedance on 2018/5/18.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public struct SystemContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message

    public typealias SystemType = RustPB.Basic_V1_Content.SystemType
    public typealias SystemContentValue = RustPB.Basic_V1_Content.SystemContentValue
    public typealias SystemExtraContent = RustPB.Basic_V1_Content.SystemExtraContent
    public typealias SystemGuideContent = RustPB.Basic_V1_SystemGuideContent
    public typealias SystemNewTopicContent = RustPB.Basic_V1_Content.NewTopicSystemMessageExtraContent
    public typealias SystemGuideActionButton = RustPB.Basic_V1_SystemGuideCTAItem
    public typealias ContentValue = SystemContentValue.ContentValue
    public typealias ContentValueType = RustPB.Basic_V1_Content.ContentValueType
    public typealias ActType = RustPB.Basic_V1_Content.SystemMessageAction.ActType
    public typealias ActionPayload = RustPB.Im_V1_GetMessageActionPayloadResponse
    public typealias SystemMessageItemAction = RustPB.Basic_V1_SystemMessageItemAction

    // 固有字段
    public let template: String
    public let values: [String: String]
    public let systemType: SystemType
    public let systemContentValues: [String: SystemContentValue]
    public let systemExtraContent: SystemExtraContent
    public let itemActions: [Int32: SystemMessageItemAction]
    public let version: Int32

    // 附加字段
    public var triggerUser: Chatter?
    public var callee: Chatter?
    public var manipulator: Chatter? // voip 系统消息 触发行为的 chatter

    public var e2eeCallInfo: E2EECallInfo?
    public var btyeViewInfo: ByteViewInfo?

    // for ByteView
    public init(template: String,
                values: [String: String],
                btyeViewInfo: ByteViewInfo,
                systemContentValues: [String: SystemContentValue],
                systemExtraContent: SystemExtraContent,
                itemActions: [Int32: SystemMessageItemAction],
                version: Int32) {
        self.init(
            template: template,
            values: values,
            systemType: btyeViewInfo.type,
            systemContentValues: systemContentValues,
            systemExtraContent: systemExtraContent,
            itemActions: itemActions,
            version: version
        )
        self.btyeViewInfo = btyeViewInfo
    }

    // for E2EE
    public init(template: String,
                values: [String: String],
                systemType: SystemType,
                e2eeCallInfo: E2EECallInfo?,
                systemContentValues: [String: SystemContentValue],
                systemExtraContent: SystemExtraContent,
                itemActions: [Int32: SystemMessageItemAction],
                version: Int32) {
        self.init(template: template, values: values, systemType: systemType, systemContentValues: systemContentValues, systemExtraContent: systemExtraContent,
itemActions: itemActions, version: version)
        self.e2eeCallInfo = e2eeCallInfo
    }

    public init(
        template: String,
        values: [String: String],
        systemType: SystemType,
        systemContentValues: [String: SystemContentValue],
        systemExtraContent: SystemExtraContent,
        itemActions: [Int32: SystemMessageItemAction],
        version: Int32
    ) {
        self.template = template
        self.values = values
        self.systemType = systemType
        self.systemContentValues = systemContentValues
        self.systemExtraContent = systemExtraContent
        self.itemActions = itemActions
        self.version = version
    }

    public static func transform(pb: PBModel) -> SystemContent {
        // byteView message content
        if ByteViewInfo.systemTypes.contains(pb.content.systemType),
            !pb.content.vcFromID.isEmpty,
            !pb.content.vcToID.isEmpty {
            let byteViewInfo = ByteViewInfo(fromID: pb.content.vcFromID,
                                            toID: pb.content.vcToID,
                                            meetID: pb.content.vcMeetingID,
                                            type: pb.content.systemType,
                                            isVoiceCall: pb.content.isVoiceCall)
            return SystemContent(template: pb.content.template,
                                 values: pb.content.values,
                                 btyeViewInfo: byteViewInfo,
                                 systemContentValues: pb.content.systemContentValues,
                                 systemExtraContent: pb.content.systemExtraContent,
                                 itemActions: pb.content.itemActions,
                                 version: pb.content.systemMessageVersion)
        }

        var e2eeCallInfo: E2EECallInfo?
        if !pb.content.e2EeFromID.isEmpty,
            !pb.content.e2EeToID.isEmpty {
            e2eeCallInfo = E2EECallInfo(
                e2EeFromID: pb.content.e2EeFromID,
                e2EeToID: pb.content.e2EeToID,
                manipulatorID: pb.content.triggerID)
        }

        return SystemContent(
            template: pb.content.template,
            values: pb.content.values,
            systemType: pb.content.systemType,
            e2eeCallInfo: e2eeCallInfo,
            systemContentValues: pb.content.systemContentValues,
            systemExtraContent: pb.content.systemExtraContent,
            itemActions: pb.content.itemActions,
            version: pb.content.systemMessageVersion
        )
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if let triggerId = self.triggerId,
            let triggerUser = try? Chatter.transformChatChatter(entity: entity, chatID: message.channel.id, id: triggerId) {
            self.triggerUser = triggerUser
        }
        if let calleeId = self.calleeId,
            let calleeUser = try? Chatter.transformChatChatter(entity: entity, chatID: message.channel.id, id: calleeId) {
            self.callee = calleeUser
        }
    }

    public func decode() -> String {
        var content = template
        for (key, value) in values {
            content = content.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return content
    }
}

public extension SystemContent {
    // e2ee 字段
    struct E2EECallInfo {
        public var e2EeFromID: String
        public var e2EeToID: String
        public var manipulatorID: String?

        public init(e2EeFromID: String, e2EeToID: String, manipulatorID: String) {
            self.e2EeFromID = e2EeFromID
            self.e2EeToID = e2EeToID
            self.manipulatorID = manipulatorID
        }
    }

    // byteViewInfo字段
    struct ByteViewInfo {
        static let systemTypes: [SystemContent.SystemType] =
            SystemContent.SystemType.byteViewTypes + [.vcCallDuration]
        public var type: RustPB.Basic_V1_Content.SystemType
        public var isVoiceCall: Bool
        public var fromID: String
        public var toID: String
        public var durationStr: String?
        public var meetID: String?
        public init(
            fromID: String,
            toID: String,
            meetID: String?,
            type: RustPB.Basic_V1_Content.SystemType,
            isVoiceCall: Bool
        ) {
            self.fromID = fromID
            self.toID = toID
            self.meetID = meetID
            self.type = type
            self.isVoiceCall = isVoiceCall
        }
    }
}

public extension SystemContent.SystemType {
    static var voipCallTypes: [SystemContent.SystemType] {
        return [
            .userCallE2EeVoiceOnCancell,
            .userCallE2EeVoiceOnMissing,
            .userCallE2EeVoiceDuration,
            .userCallE2EeVoiceWhenRefused,
            .userCallE2EeVoiceWhenOccupy
        ]
    }

    static var byteViewTypes: [SystemContent.SystemType] {
        return [
            .vcCallHostCancel,
            .vcCallPartiNoAnswer,
            .vcCallPartiCancel,
            .vcCallHostBusy,
            .vcCallPartiBusy,
            .vcCallFinishNotice,
            .vcCallConnectFail,
            .vcCallDisconnect
        ]
    }

    static var calendarTypes: [SystemContent.SystemType] {
        return []
    }

    static var redPaketTypes: [SystemContent.SystemType] {
        return [
            .grabOtherHongbao,
            .otherGrabMyHongbao,
            .lastHongbaoIsGrabbed,
            .sendHongbaoMessageFailed,
            .simplifyOtherGrabMyHongbao,
            .simplifyOtherGrabMyHongbaoNotOverOutNum
        ]
    }
}
