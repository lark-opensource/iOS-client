//
//  BoxFeedCardDigestVM.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/5/23.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkModel
import RustPB
import UniverseDesignColor
import LarkEmotion

final class BoxFeedCardDigestVM: FeedCardDigestVM {
    // VM 数据
    let digestContent: FeedCardDigestVMType

    // 表明组件类别
    var type: FeedCardComponentType {
        return .digest
    }

    // 在子线程生成view data
    required init(feedPreview: FeedPreview, helper: FeedDigestInfoHelper) {
        if feedPreview.basicMeta.unreadCount > 0 {
            self.digestContent = .attributedText(helper.getUnreadDigestForBoxFeed())
        } else {
            self.digestContent = .attributedText(helper.getHasReadDigestForBox())
        }
    }
}
