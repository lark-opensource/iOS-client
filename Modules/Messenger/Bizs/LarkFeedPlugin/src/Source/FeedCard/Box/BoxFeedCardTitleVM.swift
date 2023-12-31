//
//  BoxFeedCardTitleVM.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/5/20.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import LarkFeedBase

// MARK: - ViewModel
final class BoxFeedCardTitleVM: FeedCardTitleVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .title
    }

    // VM 数据
    let title: String

    // 在子线程生成view data
    required init() {
        // BoxCell的名称固定为：会话盒子
        self.title = BundleI18n.LarkFeedPlugin.Lark_Core_CollapsedChats_FeedName
    }
}
