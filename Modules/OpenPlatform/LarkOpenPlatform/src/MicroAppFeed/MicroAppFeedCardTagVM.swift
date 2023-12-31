//
//  MicroAppFeedCardTagVM.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/5/30.
//
#if MessengerMod
import Foundation
import LarkBizTag
import LarkFeedBase
import LarkModel
import LarkOpenFeed
import RustPB

final class MicroAppFeedCardTagVM: FeedCardTagVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .tag
    }

    // VM 数据
    let tagBuilder: TagViewBuilder

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        let builder = OPTagViewBuilder()
        builder.reset(with: [])
        builder.isApp(true)
        self.tagBuilder = builder
    }
}
#endif
