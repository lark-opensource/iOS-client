//
//  BoxFeedCardModule.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/5/20.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkContainer
import LarkSwipeCellKit
import RustPB
import LarkModel
import LarkFeed

class BoxFeedCardModule: FeedCardBaseModule {
    // [必须实现]表明自己的业务类型
    override var type: FeedPreviewType {
        return .box
    }

    // [必须实现] 关联业务的实体数据。feed框架内部使用，或者是使用feed框架的业务使用
    override func bizData(feedPreview: FeedPreview) -> FeedPreviewBizData {
        var shortcutChannel = Basic_V1_Channel()
        shortcutChannel.id = feedPreview.id
        shortcutChannel.type = .unknown
        let data = FeedPreviewBizData(entityId: feedPreview.id,
                                   shortcutChannel: shortcutChannel)
        return data
    }

    // [必须实现] 向feed card容器提供组装组件的配置信息。如果提供的默认的组装信息，已经满足业务方，则不需要重新配置，否则需要重写packInfo
    override var packInfo: FeedCardComponentPackInfo {
        let info = FeedCardComponentPackInfo(
            avatarArea: [.avatar],
            topArea: [],
            titleArea: [.title],
            subTitleArea: [],
            statusArea: [],
            digestArea: [.digest],
            bottomArea: [])
        return info
    }

    // [可选实现] 当对基础组件有异化数据诉求时，可实现这个方法
    override func customComponentVM(componentType: FeedCardComponentType, feedPreview: FeedPreview) -> FeedCardBaseComponentVM? {
        switch componentType {
        case .title:
            return BoxFeedCardTitleVM()
        case .digest:
            let helper = FeedDigestInfoHelper(feedPreview: feedPreview,
                                              userResovler: feedCardContext.userResolver)
            return BoxFeedCardDigestVM(feedPreview: feedPreview, helper: helper)
        case .avatar:
            return BoxFeedCardAvatarVM(feedPreview: feedPreview)
        default:
            return nil
        }
    }

    override func leftActionTypes(feedPreview: FeedPreview,
                                  types: [FeedCardSwipeActionType]) -> [FeedCardSwipeActionType] {
        return []
    }

    // 返回从左往右滑动的 actions，返回 [] 可禁用从左往右滑动手势，返回过滤后的从左往右滑动的 actions
    override func rightActionTypes(feedPreview: FeedPreview,
                                   types: [FeedCardSwipeActionType]) -> [FeedCardSwipeActionType] {
        return []
    }

    override func isSupportMute(feedPreview: FeedPreview) -> Bool {
        return false
    }

    // MARK: - FeedAction 能力
    override func getActionTypes(model: FeedActionModel, event: FeedActionEvent) -> [FeedActionType] {
        var types: [FeedActionType] = []
        switch event {
        case .leftSwipe:
            types = []
        case .rightSwipe:
            types = []
        case .longPress:
            types.append(.clearBadge)
            if model.feedPreview.preview.chatData.chatterType == .bot {
                types.append(.blockMsg)
            }
        @unknown default:
            break
        }
        return types
    }
}
