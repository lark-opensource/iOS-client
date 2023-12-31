//
//  DocFeedCardTagVM.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/5/30.
//
#if MessengerMod

import Foundation
import RustPB
import LarkModel
import LarkOpenFeed
import LarkFeedBase
import LarkContainer
import LarkBizTag
import LarkCore
import LarkMessengerInterface

final class DocFeedCardTagVM: FeedCardTagVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .tag
    }

    // VM 数据
    let tagBuilder: TagViewBuilder

    // 在子线程生成view data
    required init(feedPreview: FeedPreview, userResolver: UserResolver, dependency: DocFeedCardDependency?) {
        let builder = DocTagViewBuilder()
        if let dependency = dependency,
           !isCustomer(tenantId: dependency.currentTenantId) { // C端用户
            var isExternal = false
            UserStyle.on(.externalTag, userType: dependency.accountType).apply(on: {
                isExternal = true
            }, off: {})
            builder.reset(with: [])
            builder.isExternal(feedPreview.extraMeta.crossTenant && isExternal)
            builder.addTags(with: Basic_V1_TagData.transform(tagDataItems: feedPreview.uiMeta.tagDataItems))
        }
        self.tagBuilder = builder
    }
}
#endif
