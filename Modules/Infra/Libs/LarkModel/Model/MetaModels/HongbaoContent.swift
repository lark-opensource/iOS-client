//
//  HongbaoContent.swift
//  Action
//
//  Created by lichen on 2018/11/1.
//

import Foundation
import UIKit
import RustPB

public struct HongbaoContent: MessageContent {
    public typealias TypeEnum = RustPB.Basic_V1_HongbaoContent.TypeEnum

    public typealias PBModel = RustPB.Basic_V1_Message

    public var id: String
    public var subject: String
    public var type: HongbaoContent.TypeEnum
    /// 是否已经点过
    public var clicked: Bool
    /// 是否已经领取
    public var isGrabbed: Bool
    /// 是否已领完
    public var isGrabbedFinish: Bool
    /// 是否已经过期
    public var isExpired: Bool
    public var cover: RustPB.Basic_V1_HongbaoCover

    public let canGrab: Bool
    public let previewUserIds: [Int64] /// 专属红包部分可领取用户列表
    public var previewChatters: [Chatter] = []
    public let totalNum: Int32 /// 红包总个数（专属红包总人数)

    public init(id: String,
                subject: String,
                type: HongbaoContent.TypeEnum,
                clicked: Bool,
                isGrabbed: Bool,
                isGrabbedFinish: Bool,
                isExpired: Bool,
                cover: RustPB.Basic_V1_HongbaoCover,
                canGrab: Bool,
                previewUserIds: [Int64],
                totalNum: Int32) {
        self.id = id
        self.subject = subject
        self.type = type
        self.clicked = clicked
        self.isGrabbed = isGrabbed
        self.isGrabbedFinish = isGrabbedFinish
        self.isExpired = isExpired
        self.cover = cover
        self.canGrab = canGrab
        self.previewUserIds = previewUserIds
        self.totalNum = totalNum
    }

    public static func transform(pb: PBModel) -> HongbaoContent {
        return HongbaoContent(
            id: pb.content.hongbaoContent.id,
            subject: pb.content.hongbaoContent.subject,
            type: pb.content.hongbaoContent.type,
            clicked: pb.content.hongbaoContent.clicked,
            isGrabbed: pb.content.hongbaoContent.grabbed,
            isGrabbedFinish: pb.content.hongbaoContent.grabbedFinish,
            isExpired: pb.content.hongbaoContent.isExpired,
            cover: pb.content.hongbaoContent.cover,
            canGrab: pb.content.hongbaoContent.canGrab,
            previewUserIds: pb.content.hongbaoContent.previewUserIds,
            totalNum: pb.content.hongbaoContent.totalNum
        )
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        self.previewChatters = self.previewUserIds.compactMap { chatterId -> Chatter? in
            return try? Chatter.transformChatChatter(entity: entity, chatID: message.channel.id, id: "\(chatterId)")
        }
    }
}
