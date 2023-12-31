//
//  FeedCodeConfig.swift
//  LarkFeed
//
//  Created by liuxianyu on 2021/12/29.
//

import Foundation

struct FeedSDKErrorCode {
   static let outOfGroup: Int = 111_001
   static let duplicateLabelName: Int = 390_000
}

struct FeedLocalCode {
    // 是否为缓存数据的标记位
    static let feedKVStorageFlag: Int64 = -1

    static let invalidUpdateTime: Int = -2
}

struct FeedSortPosition {
    static let boxPreferredRank: Int = 12 // 折叠会话最靠前的排序位置
}
