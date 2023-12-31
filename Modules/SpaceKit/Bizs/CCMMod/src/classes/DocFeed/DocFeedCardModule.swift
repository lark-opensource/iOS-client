//
//  DocFeedCardModule.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/5/20.
//
#if MessengerMod

import Foundation
import RustPB
import LarkModel
import LarkOpenFeed
import LarkFeedBase
import LarkContainer
import LarkSceneManager
import RxSwift
import RxCocoa
import LarkUIKit
import LarkNavigator
import Homeric
import LKCommonsTracker
import LarkMessengerInterface
import LKCommonsLogging

class DocFeedCardModule: FeedCardBaseModule {
    @ScopedInjectedLazy var dependency: DocFeedCardDependency?

    static let logger = Logger.log(DocFeedCardModule.self, category: "DocFeed")
    // [必须实现]表明自己的业务类型
    override var type: FeedPreviewType {
        return .docFeed
    }

    // [必须实现] 关联业务的实体数据。feed框架内部使用，或者是使用feed框架的业务使用
    override func bizData(feedPreview: FeedPreview) -> FeedPreviewBizData {
        var shortcutChannel = Basic_V1_Channel()
        shortcutChannel.id = feedPreview.id
        shortcutChannel.type = .doc
        let data = FeedPreviewBizData(entityId: feedPreview.id, shortcutChannel: shortcutChannel)
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
            digestArea: [.reaction, .digest, .mute, .mention],
            bottomArea: [])
        return info
    }

    // [可选实现] 当对基础组件有异化数据诉求时，可实现这个方法
    override func customComponentVM(componentType: FeedCardComponentType,
                                    feedPreview: FeedPreview) -> FeedCardBaseComponentVM? {
        switch componentType {
        case .avatar:
            return DocFeedCardAvatarVM(feedPreview: feedPreview, userResolver: feedCardContext.userResolver)
        case .tag:
            return DocFeedCardTagVM(feedPreview: feedPreview, userResolver: feedCardContext.userResolver, dependency: dependency)
        default:
            return nil
        }
    }

    // mute操作，由各业务实现
    override func setMute(feedPreview: FeedPreview) -> Single<Void> {
        dependency?.changeMute(feedId: feedPreview.id, to: !feedPreview.basicMeta.isRemind) ?? .just(())
    }

    // 用于返回 cell 拖拽手势
    override func supportDragScene(feedPreview: FeedPreview) -> Scene? {
        let scene = LarkSceneManager.Scene(
            key: "Docs",
            id: feedPreview.preview.docData.docURL,
            title: feedPreview.uiMeta.name,
            userInfo: [:],
            windowType: "docs",
            createWay: "drag")
        return scene
    }

    // MARK: - FeedAction 能力
    override func getActionTypes(model: FeedActionModel, event: FeedActionEvent) -> [FeedActionType] {
        var types: [FeedActionType] = []
        switch event {
        case .leftSwipe:
            types.append(.flag)
            types.append(.shortcut)
        case .rightSwipe:
            types.append(.done)
        case .longPress:
            types += getActionTypes(model: model, event: .leftSwipe) +
                     getActionTypes(model: model, event: .rightSwipe)
            types.append(.mute)
            types.append(.clearBadge)
        @unknown default:
            break
        }
        return types
    }
}
#endif
