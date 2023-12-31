//
//  MicroAppFeedCardModule.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/5/20.
//
#if MessengerMod
import Foundation
import RustPB
import LarkModel
import LarkContainer
import RxSwift
import RxCocoa
import LarkUIKit
import LarkNavigator
import LarkOpenFeed
import LarkFeedBase
import LarkMessengerInterface

class MicroAppFeedCardModule: FeedCardBaseModule {
    @ScopedInjectedLazy var dependency: MicroAppFeedCardDependency?

    // [必须实现]表明自己的业务类型
    override var type: FeedPreviewType {
        return .microApp
    }

    // [必须实现] 关联业务的实体数据。feed框架内部使用，或者是使用feed框架的业务使用
    override func bizData(feedPreview: FeedPreview) -> FeedPreviewBizData {
        var shortcutChannel = Basic_V1_Channel()
        shortcutChannel.id = feedPreview.id
        shortcutChannel.type = .openapp
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
            digestArea: [.digest, .mute],
            bottomArea: [])
        return info
    }

    // [可选实现] 当对基础组件有异化数据诉求时，可实现这个方法
    override func customComponentVM(componentType: FeedCardComponentType,
                                    feedPreview: FeedPreview) -> FeedCardBaseComponentVM? {
        switch componentType {
        case .tag:
            return MicroAppFeedCardTagVM(feedPreview: feedPreview)
        default:
            return nil
        }
    }

    // mute操作，由各业务实现
    override func setMute(feedPreview: FeedPreview) -> Single<Void> {
        dependency?.changeMute(feedId: feedPreview.id, to: !feedPreview.basicMeta.isRemind) ?? .just(())
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
