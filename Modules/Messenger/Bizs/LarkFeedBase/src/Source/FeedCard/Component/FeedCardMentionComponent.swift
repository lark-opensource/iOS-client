//
//  FeedCardMentionComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkBizAvatar
import LarkModel
import LarkOpenFeed
import RustPB
import UniverseDesignColor

// MARK: - Factory
public class FeedCardMentionFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .mention
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardMentionComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardMentionComponentView()
    }
}

// MARK: - ViewModel
public protocol FeedCardMentionVM: FeedCardBaseComponentVM {
    var isShowMention: Bool { get }
    var avatarItem: FeedCardAvatarUrlItem { get }
    var atInfoType: FeedCardMentionAtInfoType { get }
    var feedId: String { get }
    var feedCardType: FeedPreviewType { get }
}

class FeedCardMentionComponentVM: FeedCardMentionVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .mention
    }

    // VM 数据
    let avatarItem: FeedCardAvatarUrlItem
    let isShowMention: Bool
    let atInfoType: FeedCardMentionAtInfoType
    let feedId: String
    let feedCardType: FeedPreviewType

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        let avatarItem = FeedCardAvatarUrlItem(
            entityId: feedPreview.uiMeta.mention.atInfo.userID,
            avatarKey: feedPreview.uiMeta.mention.atInfo.avatarKey)
        self.avatarItem = avatarItem
        self.isShowMention = feedPreview.uiMeta.mention.hasAtInfo
        self.atInfoType = feedPreview.uiMeta.mention.atInfo.type == .all ? .all : .me
        self.feedId = feedPreview.id
        self.feedCardType = feedPreview.basicMeta.feedCardType
    }
}

public enum FeedCardMentionAtInfoType {
    case all, me
}

// MARK: - View
class FeedCardMentionComponentView: FeedCardBaseComponentView {
    // 组件类别
    var type: FeedCardComponentType {
        return .mention
    }

    var layoutInfo: FeedCardComponentLayoutInfo? {
        return FeedCardComponentLayoutInfo(padding: nil, width: Cons.atIconSize, height: Cons.atIconSize)
    }

    func creatView() -> UIView {
        return LarkMedalAvatar()
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let atAvatarView = view as? LarkMedalAvatar,
              let vm = vm as? FeedCardMentionVM else { return }
        view.isHidden = !vm.isShowMention
        guard !view.isHidden else { return }
        atAvatarView.updateBorderSize(CGSize.square(Cons.atIconBorderSize))
        switch vm.atInfoType {
        case .me:     atAvatarView.updateBorderImage(Resources.LarkFeedBase.atMeImage)
        case .all:    atAvatarView.updateBorderImage(Resources.LarkFeedBase.atAllImage)
        }

        let entityId = vm.avatarItem.entityId
        let avatarKey = vm.avatarItem.avatarKey
        guard !entityId.isEmpty, !avatarKey.isEmpty else {
            atAvatarView.image = nil
            return
        }
        atAvatarView.setAvatarByIdentifier(
            entityId,
            avatarKey: avatarKey,
            scene: .Feed,
            avatarViewParams: .init(sizeType: .size(Cons.atIconSize)),
            completion: { result in
                if case let .failure(error) = result {
                    let info = "id: \(vm.feedId), type: \(vm.feedCardType), avatarKey: \(avatarKey), entityId: \(entityId)"
                    FeedBaseContext.log.error("feedlog/feedcard/render/atAvatar. \(info)", error: error)
                }
            })
    }

    enum Cons {
        private static let atIconDefaultSize: CGFloat = 20.0
        static var atIconSize: CGFloat { .auto(atIconDefaultSize) }
        static var atIconBorderSize: CGFloat { atIconSize + .auto(4) }
    }
}
