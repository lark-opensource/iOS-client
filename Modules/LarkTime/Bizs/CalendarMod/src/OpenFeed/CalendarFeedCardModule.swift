//
//  CalendarFeedCardModule.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/8/16.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkContainer
import LarkSwipeCellKit
import RustPB
import LarkModel
import RxSwift
import RxCocoa
import LarkBizTag
import LarkAlertController
import LarkUIKit
import LarkNavigator
import LarkBizAvatar
import LarkEmotion
import LarkSceneManager
import Calendar

class CalendarFeedCardModule: FeedCardBaseModule {
    @ScopedInjectedLazy private var calendarDependency: CalendarDependency?

    // [必须实现]表明自己的业务类型
    override var type: FeedPreviewType {
        return .calendar
    }

    // [必须实现] 关联业务的实体数据。feed框架内部使用，或者是使用feed框架的业务使用
    override func bizData(feedPreview: FeedPreview) -> FeedPreviewBizData {
        var shortcutChannel = Basic_V1_Channel()
        shortcutChannel.id = feedPreview.id
        shortcutChannel.type = .appFeed
        let data = FeedPreviewBizData(entityId: feedPreview.id, shortcutChannel: shortcutChannel)
        return data
    }

    // [必须实现] 向feed card容器提供组装组件的配置信息。如果提供的默认的组装信息，已经满足业务方，则不需要重新配置，否则需要重写packInfo
    override var packInfo: FeedCardComponentPackInfo {
        let info = FeedCardComponentPackInfo(
            avatarArea: [.avatar],
            topArea: [],
            titleArea: [.title],
            subTitleArea: [.subtitle],
            statusArea: [.flag, .status],
            digestArea: [],
            bottomArea: [])
        return info
    }

    // [可选实现] 当对基础组件有异化数据诉求时，可实现这个方法
    override func customComponentVM(componentType: FeedCardComponentType,
                                    feedPreview: FeedPreview) -> FeedCardBaseComponentVM? {
        switch componentType {
        case .avatar:
            return CalendarFeedCardAvatarVM(feedPreview: feedPreview, userResolver: feedCardContext.userResolver)
        case .title:
            return CalendarFeedCardTitleVM(feedPreview: feedPreview)
        case .status:
            return CalendarFeedCardStatusVM(feedPreview: feedPreview)
        case .subtitle:
            return CalendarFeedCardSubtitleVM(feedPreview: feedPreview,
                                               dependency: calendarDependency)
        default:
            return nil
        }
    }

    // 是否支持mute操作
    override func isSupportMute(feedPreview: FeedPreview) -> Bool {
        return false
    }

    // MARK: - FeedAction 能力
    override func getActionTypes(model: FeedActionModel, event: FeedActionEvent) -> [FeedActionType] {
        var types: [FeedActionType] = []
        switch event {
        case .leftSwipe:
            if model.bizType != .done {
                types.append(.flag)
            }
            if model.bizType != .done {
                types.append(.shortcut)
            }
        case .rightSwipe:
            if model.bizType == .inbox {
                types.append(.done)
            }
        case .longPress:
            types += getActionTypes(model: model, event: .leftSwipe) +
                     getActionTypes(model: model, event: .rightSwipe)
        @unknown default:
            types = []
        }
        return types
    }
}
