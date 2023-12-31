//
//  ShortcutCellViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/15.
//

import Foundation
import RxSwift
import RxDataSources
import LarkSDKInterface
import LarkModel
import RustPB
import LarkBadge
import LKCommonsLogging
import LarkFeedBase
import LarkContainer
import LarkOpenFeed
///
/// 代表单个置顶数据的view model
///

struct ShortcutRenderData: Equatable {
    let name: String
    var avatarVM: FeedCardAvatarViewModel?

    public static func == (lhs: ShortcutRenderData, rhs: ShortcutRenderData) -> Bool {
        return lhs.name == rhs.name
        && lhs.avatarVM == rhs.avatarVM
    }
}

final class ShortcutCellViewModel {
    let userResolver: UserResolver
    private var result: ShortcutResult
    let renderData: ShortcutRenderData

    // shortcut 数据
    var shortcut: RustPB.Feed_V1_Shortcut {
        return result.shortcut
    }

    var id: String {
        return result.shortcut.channel.id
    }

    var position: Int {
        return Int(result.shortcut.position)
    }

    // feed card 数据
    var preview: FeedPreview {
        return result.preview
    }

    var feedID: String {
        result.preview.id
    }

    var unreadCount: Int {
        Int(result.preview.basicMeta.unreadCount)
    }

    var isRemind: Bool {
        return result.preview.basicMeta.isRemind
    }

    var hasAtInfo: Bool {
        return result.preview.uiMeta.mention.hasAtInfo
    }

    var isCrypto: Bool {
        return result.preview.preview.chatData.isCrypto
    }

    var isP2PAi: Bool {
        return result.preview.preview.chatData.isP2PAi
    }

    init(result: ShortcutResult,
         userResolver: UserResolver,
         feedCardModuleManager: FeedCardModuleManager) {
        self.result = result
        self.userResolver = userResolver
        let name: String

        let titleVM = FeedCardContext.buildComponentVO(
            componentType: .title,
            feedPreview: result.preview,
            feedCardModuleManager: feedCardModuleManager)
        if let titleVM = titleVM as? FeedCardTitleVM {
            name = titleVM.title
        } else {
            name = ""
        }
        let avatarVM = FeedCardContext.buildComponentVO(
            componentType: .avatar,
            feedPreview: result.preview,
            feedCardModuleManager: feedCardModuleManager)
            as? FeedCardAvatarVM
        self.renderData = ShortcutRenderData(name: name, avatarVM: avatarVM?.avatarViewModel)
    }

    func update(feedPreview: FeedPreview,
                feedCardModuleManager: FeedCardModuleManager) -> ShortcutCellViewModel {
        let result = ShortcutResult(shortcut: self.result.shortcut, preview: feedPreview)
        return ShortcutCellViewModel(result: result,
                                     userResolver: userResolver,
                                     feedCardModuleManager: feedCardModuleManager)
    }
}

// 为埋点暴露两个属性
extension ShortcutCellViewModel {
    var chatSubType: String {
        result.preview.chatSubType
    }

    var charTotalType: String {
        result.preview.chatTotalType
    }
}

extension ShortcutCellViewModel {
    var description: String {
        return result.description
    }
}
