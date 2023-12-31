//
//  Attachment.swift
//  Lark
//
//  Created by lichen on 2017/8/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
/**
 必须由通过 AttachmentUploader attachemnt(data: Data, type: Attachment.FileType) -> Attachment 构建
 */
public final class Attachment {
    public enum FileType: String {
        case image
        case audio
        case file
        case secureImage
    }

    public var key: String
    public var type: Attachment.FileType
    public var info: [String: String]

    public init(key: String, type: Attachment.FileType, info: [String: String] = [:]) {
        self.key = key
        self.type = type
        self.info = info
    }
}
