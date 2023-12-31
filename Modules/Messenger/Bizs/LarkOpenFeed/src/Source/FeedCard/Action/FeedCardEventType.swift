//
//  FeedCardEventType.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/5/22.
//

import Foundation

// 事件类型
public enum FeedCardEventType {
    case selected           // 选中
    case highlighted        // 高亮
    case prepareForReuse    // 复用
    case willDisplay        // feed将要展示
    case didEndDisplay      // feed结束显示
    case rendered           // feed渲染完成
}

// 事件类型关联的参数
public enum FeedCardEventValue {
    case none
    case selected(Bool)
    case highlighted(Bool)
    case rendered(FeedCardComponentType, Any)
}
