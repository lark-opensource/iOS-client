//
//  MessageContent.swift
//  Model
//
//  Created by qihongye on 2018/3/13.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import RustPB

public protocol MessageContent {
    mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message)
    // 消息链接化场景不依赖Basic_V1_Entity结构
    // previewID: 最外层消息链接的previewID
    mutating func complement(previewID: String, messageLink: RustPB.Basic_V1_MessageLink, message: Message)
}

extension MessageContent {
    public func complement(previewID: String, messageLink: RustPB.Basic_V1_MessageLink, message: Message) {}
}

public struct UnknownContent: MessageContent {
    public init() {}
    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}
}

extension RustPB.Basic_V1_Abbreviation {
    public func getAbbreviationMap(
        _ abbreviationMap: [String: Message.AbbreviationEntity]?
    ) -> [String: [Basic_V1_Abbreviation.entity]] {
        return abbrElementRef
            .mapValues({ $0.abbrs.compactMap({ $0 }) })
            .filter({ !$0.value.isEmpty })
    }
}
