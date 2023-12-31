//
//  MailFeedCardModule.swift
//  LarkMail
//
//  Created by ByteDance on 2023/9/15.
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
import MailSDK
#if MessengerMod
import LarkMessengerInterface
#endif

class MailFeedCardModule: FeedCardBaseModule {
//    @ScopedInjectedLazy private var mailDependency: CalDependency?

    // [必须实现]表明自己的业务类型
    override var type: FeedPreviewType {
        return .mailFeed
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
            titleArea: [.title, .tag],
            subTitleArea: [],
            statusArea: [.time, .flag],
            digestArea: [.digest, .mute],
            bottomArea: [])
        return info
    }
    
    override func customComponentVM(componentType: FeedCardComponentType,
                                    feedPreview: FeedPreview) -> FeedCardBaseComponentVM? {
        switch componentType {
            case .digest:
                return MailFeedCardDigestVM(feedPreview: feedPreview)
            default:
                return nil
        }
    }
    
    // 是否支持mute操作
    override func isSupportMute(feedPreview: FeedPreview) -> Bool {
        return true
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
            types.append(.mute)
            types.append(.clearBadge)
        @unknown default:
            types = []
        }
        return types
    }
}
