//
//  ComponentPackInfo.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/1/3.
//

import Foundation
import LarkModel

// 组件组装的信息描述：描述组件在哪个坑位里
public class FeedCardComponentPackInfo {
    public let avatarArea: [FeedCardComponentType]
    public let topArea: [FeedCardComponentType]
    public let titleArea: [FeedCardComponentType]
    public let subTitleArea: [FeedCardComponentType]
    public let statusArea: [FeedCardComponentType]
    public let digestArea: [FeedCardComponentType]
    public let bottomArea: [FeedCardComponentType]

    public init(avatarArea: [FeedCardComponentType],
                topArea: [FeedCardComponentType],
                titleArea: [FeedCardComponentType],
                subTitleArea: [FeedCardComponentType],
                statusArea: [FeedCardComponentType],
                digestArea: [FeedCardComponentType],
                bottomArea: [FeedCardComponentType]) {
        self.avatarArea = avatarArea
        self.topArea = topArea
        self.titleArea = titleArea
        self.subTitleArea = subTitleArea
        self.statusArea = statusArea
        self.digestArea = digestArea
        self.bottomArea = bottomArea
    }

    // 获取该feed下所用到的所有组件类型
    public var allTypes: [FeedCardComponentType] {
        return avatarArea + topArea + titleArea + subTitleArea + statusArea + digestArea + bottomArea
    }

    // 提供基础的组装信息
    public static func `default`() -> FeedCardComponentPackInfo {
        return FeedCardComponentPackInfo(avatarArea: [.avatar],
                                         topArea: [],
                                         titleArea: [.title, .tag],
                                         subTitleArea: [],
                                         statusArea: [.time, .flag],
                                         digestArea: [.digest, .mute],
                                         bottomArea: [])
    }

    public static var statusShowOrder: [FeedCardComponentType] {
        return [.flag, .status, .time]
    }
}
