//
//  ThreadFeedCardModule.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/5/17.
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
import LarkFeed
import LarkBizTag
import LarkMessengerInterface
import LarkUIKit
import LarkNavigator
import LarkBizAvatar
import LarkEmotion
import LarkSceneManager

class ThreadFeedCardModule: FeedCardBaseModule {
    @ScopedInjectedLazy var dependency: ThreadFeedCardDependency?

    // [必须实现]表明自己的业务类型
    override var type: FeedPreviewType {
        return .thread
    }

    // [必须实现] 关联业务的实体数据。feed框架内部使用，或者是使用feed框架的业务使用
    override func bizData(feedPreview: FeedPreview) -> FeedPreviewBizData {
        var shortcutChannel = Basic_V1_Channel()
        shortcutChannel.id = feedPreview.id
        shortcutChannel.type = .unknown
        let data = FeedPreviewBizData(entityId: feedPreview.preview.threadData.chatID, shortcutChannel: shortcutChannel)
        return data
    }

    // [必须实现] 向feed card容器提供组装组件的配置信息。如果提供的默认的组装信息，已经满足业务方，则不需要重新配置，否则需要重写packInfo
    override var packInfo: FeedCardComponentPackInfo {
        let info = FeedCardComponentPackInfo(
            avatarArea: [.avatar],
            topArea: [],
            titleArea: [.title, .tag],
            subTitleArea: [],
            statusArea: [.time, .flag],
            digestArea: [.reaction, .msgStatus, .digest, .mute, .mention],
            bottomArea: [])
        return info
    }

    // [可选实现] 当对基础组件有异化数据诉求时，可实现这个方法
    override func customComponentVM(componentType: FeedCardComponentType,
                                    feedPreview: FeedPreview) -> FeedCardBaseComponentVM? {
        switch componentType {
        case .digest:
            let helper = FeedDigestInfoHelper(feedPreview: feedPreview, userResovler: feedCardContext.userResolver)
            return ChatFeedCardDigestVM(feedPreview: feedPreview, helper: helper)
        case .avatar:
            return ThreadFeedCardAvatarVM(feedPreview: feedPreview)
        default:
            return nil
        }
    }

    // 返回从左往右滑动的 actions，返回 [] 可禁用从左往右滑动手势，返回过滤后的从左往右滑动的 actions
    override func rightActionTypes(feedPreview: FeedPreview,
                                   types: [FeedCardSwipeActionType]) -> [FeedCardSwipeActionType] {
        var rightActionTypes = types
        rightActionTypes.removeAll(where: { $0 == .shortcut })
        return rightActionTypes
    }

    override func isSupportMute(feedPreview: FeedPreview) -> Bool {
        if feedPreview.preview.threadData.entityType == .msgThread {
            return true
        }
        return false
    }

    // mute操作，由各业务实现
    override func setMute(feedPreview: FeedPreview) -> Single<Void> {
        dependency?.changeMute(feedId: feedPreview.id, to: !feedPreview.basicMeta.isRemind) ?? .just(())
    }

    // 用于返回 cell 拖拽手势
    override func supportDragScene(feedPreview: FeedPreview) -> Scene? {
        let scene = LarkSceneManager.Scene(
            key: "Thread",
            id: feedPreview.id,
            title: feedPreview.uiMeta.name,
            userInfo: [:],
            windowType: "channel",
            createWay: "drag")
        return scene
    }

    // MARK: - FeedAction 能力
    override func getActionTypes(model: FeedActionModel, event: FeedActionEvent) -> [FeedActionType] {
        var types: [FeedActionType] = []
        switch event {
        case .leftSwipe:
            types.append(.flag)
        case .rightSwipe:
            types.append(.done)
        case .longPress:
            types += getActionTypes(model: model, event: .leftSwipe) +
                     getActionTypes(model: model, event: .rightSwipe)

            if model.feedPreview.preview.threadData.entityType == .msgThread {
                types.append(.mute)
            }
            types.append(.clearBadge)
        @unknown default:
            break
        }
        return types
    }
}
