//
//  FeedPreviewBizData.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/8/1.
//

import Foundation
import RustPB

// [必须实现] 关联业务的实体数据。feed框架内部使用，或者是使用feed框架的业务使用
public struct FeedPreviewBizData {
    // 关联业务的实体id
    public let entityId: String

    // shortcut 支持的类型
    public let shortcutChannel: Basic_V1_Channel

    public init(entityId: String,
                shortcutChannel: Basic_V1_Channel) {
        self.entityId = entityId
        self.shortcutChannel = shortcutChannel
    }
}

// feed自身的实体数据
public protocol IFeedPreviewBasicData {
    var isTempTop: Bool { get }
    var bizType: FeedBizType { get }
    var groupType: Feed_V1_FeedFilter.TypeEnum { get }
}
