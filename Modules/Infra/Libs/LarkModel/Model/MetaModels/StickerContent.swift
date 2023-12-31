//
//  StickerContent.swift
//  LarkModel
//
//  Created by chengzhipeng-bytedance on 2018/5/18.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public struct StickerContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message

    // 固有字段
    public let key: String
    public let width: Int32
    public let height: Int32
    public let stickerID: String
    public let stickerSetID: String
    public let stickerInfo: RustPB.Basic_V1_Content.StickerInfo

    public init(
        key: String,
        width: Int32,
        height: Int32,
        stickerID: String,
        stickerSetID: String,
        stickerInfo: RustPB.Basic_V1_Content.StickerInfo) {
        self.key = key
        self.width = width
        self.height = height
        self.stickerID = stickerID
        self.stickerSetID = stickerSetID
        self.stickerInfo = stickerInfo
    }

    public static func transform(pb: PBModel) -> StickerContent {
        return StickerContent(
            key: pb.content.key,
            width: pb.content.width,
            height: pb.content.height,
            stickerID: pb.content.stickerID,
            stickerSetID: pb.content.stickerSetID,
            stickerInfo: pb.content.stickerInfo
        )
    }

    public func transformToSticker() -> RustPB.Im_V1_Sticker {
        var sticker = RustPB.Im_V1_Sticker()
        // 这里是为了兼容老数据表情没有isPaid的问题,默认值设置为true
        sticker.hasPaid_p = self.stickerInfo.hasIsPaid ? self.stickerInfo.isPaid : true
        sticker.description_p = self.stickerInfo.description_p
        sticker.stickerID = self.stickerID
        sticker.stickerSetID = self.stickerSetID
        sticker.image.key = self.key
        sticker.image.origin.key = self.key
        sticker.image.origin.width = self.width
        sticker.image.origin.height = self.height
        if !self.stickerSetID.isEmpty && self.stickerSetID != "0" {
            sticker.mode = .meme
        } else {
            sticker.mode = .sticker
        }
        return sticker
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}
}
