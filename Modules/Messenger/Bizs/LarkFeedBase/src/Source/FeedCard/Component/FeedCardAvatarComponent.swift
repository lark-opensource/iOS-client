//
//  FeedCardAvatarComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkOpenFeed
import LarkModel
import LarkBizAvatar
import SuiteAppConfig
import LarkBadge
import RustPB
import ByteWebImage
import UniverseDesignColor
import LarkZoomable

// MARK: - Factory
public class FeedCardAvatarFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .avatar
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardAvatarComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardAvatarComponentView()
    }
}

public struct FeedCardMedal: Equatable {
    public let key: String
    public let name: String

    public init(key: String,
                name: String) {
        self.key = key
        self.name = name
    }

    public static func == (lhs: FeedCardMedal, rhs: FeedCardMedal) -> Bool {
        return lhs.key == rhs.key
        && lhs.name == rhs.name
    }
}

// MARK: - ViewModel
public struct FeedCardAvatarUrlItem: Equatable {
    public let entityId: String
    public let avatarKey: String
    public let medal: FeedCardMedal?

    public init(entityId: String,
                avatarKey: String,
                medal: FeedCardMedal? = nil) {
        self.entityId = entityId
        self.avatarKey = avatarKey
        self.medal = medal
    }

    public static func == (lhs: FeedCardAvatarUrlItem, rhs: FeedCardAvatarUrlItem) -> Bool {
        return lhs.entityId == rhs.entityId
        && lhs.avatarKey == rhs.avatarKey
        && lhs.medal == rhs.medal
    }
}

public enum FeedCardAvatarDataSource: Equatable {
    case local(UIImage)
    case remote(FeedCardAvatarUrlItem)
    case custom(LarkAvatarCustommModelProtocol)

    public static func == (lhs: FeedCardAvatarDataSource, rhs: FeedCardAvatarDataSource) -> Bool {
        switch (lhs, rhs) {
        case (.local(let lt), .local(let rt)): return lt == rt
        case (.remote(let lt), .remote(let rt)): return lt == rt
        case (.custom(let lt), .custom(let rt)): return false
        default: return false
        }
    }
}

public struct FeedCardMinIconUrlItem: Equatable {
    public let entityId: String
    public let avatarKey: String

    public init(entityId: String,
                avatarKey: String) {
        self.entityId = entityId
        self.avatarKey = avatarKey
    }

    public static func == (lhs: FeedCardMinIconUrlItem, rhs: FeedCardMinIconUrlItem) -> Bool {
        return lhs.entityId == rhs.entityId
        && lhs.avatarKey == rhs.avatarKey
    }
}

public enum FeedCardMiniIconDataSource: Equatable {
    case local(UIImage)
    case remote(FeedCardMinIconUrlItem)

    public static func == (lhs: FeedCardMiniIconDataSource, rhs: FeedCardMiniIconDataSource) -> Bool {
        switch (lhs, rhs) {
        case (.local(let lt), .local(let rt)): return lt == rt
        case (.remote(let lt), .remote(let rt)): return lt == rt
        default: return false
        }
    }
}

public struct FeedCardBadgeInfo: Equatable {
    public let type: BadgeType
    public let style: LarkBadge.BadgeStyle
    public init(type: BadgeType,
                style: LarkBadge.BadgeStyle) {
        self.type = type
        self.style = style
    }

    public static func == (lhs: FeedCardBadgeInfo, rhs: FeedCardBadgeInfo) -> Bool {
        return lhs.type == rhs.type
        && lhs.style == rhs.style
    }

    public static func `default`() -> FeedCardBadgeInfo {
        return .init(type: .none, style: .weak)
    }
}

public struct FeedCardAvatarViewModel: Equatable {
    // 头像资源
    public let centerAvatarDataSource: FeedCardAvatarDataSource
    // TODO: open feed, 头像右下角的mini icon 资源
    public let miniIconDataSource: FeedCardMiniIconDataSource?
    public let miniIconProps: MiniIconProps?
    // badge 信息
    public let badgeInfo: FeedCardBadgeInfo
    public let shortcutBadgeInfo: FeedCardBadgeInfo

    // 大小头像位置是否反转,默认为false
    public let positionReversed: Bool
    // 是否有边框
    public let isBorderVisible: Bool

    // 打日志用
    public let feedId: String
    public let feedCardType: FeedPreviewType

    public init(avatarDataSource: FeedCardAvatarDataSource,
         miniIconDataSource: FeedCardMiniIconDataSource?,
         miniIconProps: MiniIconProps?,
         badgeInfo: FeedCardBadgeInfo,
         shortcutBadgeInfo: FeedCardBadgeInfo,
         positionReversed: Bool,
         isBorderVisible: Bool,
         feedId: String,
         feedCardType: FeedPreviewType) {
        self.centerAvatarDataSource = avatarDataSource
        self.miniIconDataSource = miniIconDataSource
        self.miniIconProps = miniIconProps
        self.badgeInfo = badgeInfo
        self.shortcutBadgeInfo = shortcutBadgeInfo
        self.positionReversed = positionReversed
        self.isBorderVisible = isBorderVisible
        self.feedId = feedId
        self.feedCardType = feedCardType
    }

    public static func == (lhs: FeedCardAvatarViewModel, rhs: FeedCardAvatarViewModel) -> Bool {
        return lhs.centerAvatarDataSource == rhs.centerAvatarDataSource
        && lhs.miniIconDataSource == rhs.miniIconDataSource
//        && lhs.miniIconProps == rhs.miniIconProps
        && lhs.badgeInfo == rhs.badgeInfo
        && lhs.shortcutBadgeInfo == rhs.shortcutBadgeInfo
        && lhs.positionReversed == rhs.positionReversed
        && lhs.isBorderVisible == rhs.isBorderVisible
        && lhs.feedId == rhs.feedId
        && lhs.feedCardType == rhs.feedCardType
    }
}

public protocol FeedCardAvatarVM: FeedCardBaseComponentVM {
    // 头像资源
    var avatarViewModel: FeedCardAvatarViewModel { get }
}

final class FeedCardAvatarComponentVM: FeedCardAvatarVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .avatar
    }

    // VM 数据
    let avatarViewModel: FeedCardAvatarViewModel

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        let avatarItem = FeedCardAvatarUrlItem(
            entityId: feedPreview.id,
            avatarKey: feedPreview.uiMeta.avatarKey)
        let badgeInfo = FeedCardAvatarUtil.getBadgeInfo(feedPreview: feedPreview)
        var shortcutBadgeInfo = badgeInfo
        if feedPreview.uiMeta.mention.hasAtInfo {
            shortcutBadgeInfo = FeedCardBadgeInfo(type: .icon(Resources.LarkFeedBase.badge_at_icon), style: .weak)
        }
        self.avatarViewModel = FeedCardAvatarViewModel(
            avatarDataSource: .remote(avatarItem),
            miniIconDataSource: nil,
            miniIconProps: nil,
            badgeInfo: badgeInfo,
            shortcutBadgeInfo: shortcutBadgeInfo,
            positionReversed: false,
            isBorderVisible: false,
            feedId: feedPreview.id,
            feedCardType: feedPreview.basicMeta.feedCardType)
    }
}

// MARK: - View
class FeedCardAvatarComponentView: FeedCardBaseComponentView {
    private var avatarView: FeedCardAvatarView?

    var layoutInfo: FeedCardComponentLayoutInfo? {
        return .init(padding: nil, width: Cons.size, height: Cons.size)
    }

    // 组件类别
    var type: FeedCardComponentType {
        return .avatar
    }

    func creatView() -> UIView {
        let avatarView = FeedCardAvatarView()
        self.avatarView = avatarView
        return avatarView
    }

    func subscribedEventTypes() -> [FeedCardEventType] {
        return [.prepareForReuse]
    }

    func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any) {
        if case .prepareForReuse = type {
            avatarView?.reset()
        }
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let avatarView = view as? FeedCardAvatarView,
              let vm = vm as? FeedCardAvatarVM else { return }
        let avatarViewModel = vm.avatarViewModel
        avatarView.setImage(
            avatarDataSource: avatarViewModel.centerAvatarDataSource,
            size: Cons.size,
            feedId: avatarViewModel.feedId,
            feedCardType: avatarViewModel.feedCardType)
        avatarView.set(badgeInfo: avatarViewModel.badgeInfo)
        avatarView.setBoarder(isBorderVisible: avatarViewModel.isBorderVisible, borderSize: Cons.borderSize)
        avatarView.set(
            miniIconDataSource: avatarViewModel.miniIconDataSource,
            positionReversed: avatarViewModel.positionReversed,
            miniIconSize: Cons.miniIconSize,
            miniIconMsgThreadSize: Cons.miniIconMsgThreadSize,
            feedId: avatarViewModel.feedId,
            feedCardType: avatarViewModel.feedCardType)
    }

    enum Cons {
        private static var _zoom: Zoom?
        private static var _size: CGFloat = defaultSize
        static var size: CGFloat {
            if Zoom.currentZoom != _zoom {
                let zoom = Zoom.currentZoom
                _zoom = zoom
                _size = defaultSize * zoom.scale
            }
            return _size
        }
        private static let defaultSize: CGFloat = 48.0
        static var borderSize: CGFloat { size + Resources.LarkFeedBase.avatarBorderWidth * 2 }
        private static let miniDefaultSize: CGFloat = 22.0
        static let miniIconSize: CGFloat = miniDefaultSize.auto()
        private static let miniIconMsgDefaultWidth: CGFloat = 20.0
        static let miniIconMsgThreadSize: CGFloat = miniIconMsgDefaultWidth.auto()
    }
}

final public class FeedCardAvatarView: UIView {
    public static let topBadgeMaxCount: Int = 999 // badge 数量上线

    private lazy var avatarView: LarkMedalAvatar = {
        let avatarView = LarkMedalAvatar()
        avatarView.contentMode = .scaleAspectFit
        avatarView.topBadge.setMaxNumber(to: FeedCardAvatarView.topBadgeMaxCount)
        avatarView.topBadge.isZoomable = true
        avatarView.bottomBadge.isZoomable = true
        return avatarView
    }()

    private lazy var miniIconView: BizAvatar = {
        let miniIconView = BizAvatar()
        miniIconView.avatar.backgroundColor = UIColor.clear
        return miniIconView
    }()

    public init() {
        super.init(frame: .zero)

        addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(miniIconView)
        let width = FeedCardAvatarComponentView.Cons.miniIconMsgThreadSize
        miniIconView.snp.makeConstraints { make in
            make.width.height.equalTo(width)
            make.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func reset() {
        avatarView.avatar.backgroundColor = UIColor.clear
        avatarView.image = nil
        miniIconView.avatar.backgroundColor = UIColor.clear
        miniIconView.image = nil
        miniIconView.setAvatarByIdentifier("", avatarKey: "")
    }

    public func setImage(avatarDataSource: FeedCardAvatarDataSource,
                  size: CGFloat,
                  feedId: String,
                  feedCardType: FeedPreviewType) {
        switch avatarDataSource {
        case .remote(let avatarItem):
            let entityId = avatarItem.entityId
            let avatarKey = avatarItem.avatarKey
            guard !entityId.isEmpty, !avatarKey.isEmpty else {
                avatarView.image = nil
                FeedBaseContext.log.error("feedlog/feedcard/render/avatar/empty. entityId: \(entityId), avatarKey: \(avatarKey)")
                return
            }
            avatarView.setAvatarByIdentifier(
                entityId,
                avatarKey: avatarKey,
                medalKey: avatarItem.medal?.key ?? "",
                medalFsUnit: avatarItem.medal?.name ?? "",
                scene: .Feed,
                options: [.downsampleSize(CGSize(width: size, height: size))],
                avatarViewParams: .init(sizeType: .size(size)),
                completion: { result in
                    if case let .failure(error) = result {
                        let info = "id: \(feedId), "
                        + "type: \(feedCardType), "
                        + "avatarKey: \(avatarKey), "
                        + "entityId: \(entityId)"
                        FeedBaseContext.log.error("feedlog/feedcard/render/avatar. \(info)", error: error)
                    }
                })
        case .local(let avatarImage):
            // NOTE: setAvatarByIdentifier 是为了避免下载icon和本地icon之间的复用影响
            avatarView.setAvatarByIdentifier("", avatarKey: "", completion: { [weak avatarView] _ in
                avatarView?.backgroundColor = UIColor.clear
            })
            avatarView.image = avatarImage
        case .custom(let data):
            avatarView.image = nil
            avatarView.setCustomAvatar(model: data)
        }
    }

    public func set(badgeInfo: FeedCardBadgeInfo) {
        avatarView.updateBadge(badgeInfo.type, style: badgeInfo.style)
    }

    public func setBoarder(isBorderVisible: Bool, borderSize: CGFloat) {
        FeedCardAvatarUtil.setBorderImage(avatarView: avatarView, isBorderVisible: isBorderVisible)
        avatarView.updateBorderSize(CGSize(width: borderSize, height: borderSize))
    }

    public func set(miniIcon: MiniIconProps?) {
        avatarView.setMiniIcon(miniIcon)
    }

    public func set(miniIconDataSource: FeedCardMiniIconDataSource?,
                            positionReversed: Bool,
                            miniIconSize: CGFloat,
                            miniIconMsgThreadSize: CGFloat,
                            feedId: String,
                            feedCardType: FeedPreviewType) {
        guard let miniIconDataSource = miniIconDataSource else {
            miniIconView.isHidden = true
            return
        }
        miniIconView.isHidden = false
        let size: CGFloat
        let leading: CGFloat
        if positionReversed {
            size = miniIconSize
            leading = 2
        } else {
            size = miniIconMsgThreadSize
            leading = 0
        }
        miniIconView.snp.updateConstraints { make in
            make.width.height.equalTo(size)
            make.trailing.equalToSuperview().offset(leading)
        }
        switch miniIconDataSource {
        case .remote(let avatarItem):
            let entityId = avatarItem.entityId
            let avatarKey = avatarItem.avatarKey
            let size = CGSize(width: miniIconSize, height: miniIconSize)
            guard !entityId.isEmpty, !avatarKey.isEmpty else {
                miniIconView.image = nil
                FeedBaseContext.log.error("feedlog/feedcard/render/avatar/mini/empty. entityId: \(entityId), avatarKey: \(avatarKey)")
                return
            }
            miniIconView.setAvatarByIdentifier(
                entityId,
                avatarKey: avatarKey,
                scene: .Feed,
                options: [.downsampleSize(size)],
                avatarViewParams: .init(sizeType: .size(miniIconSize)),
                completion: { result in
                    if case let .failure(error) = result {
                        // 打日志用
                        let info = "id: \(feedId), "
                        + "type: \(feedCardType), "
                        + "avatarKey: \(avatarKey), "
                        + "entityId: \(entityId)"
                        FeedBaseContext.log.error("feedlog/feedcard/render/avatar/mini. \(info)", error: error)
                    }
                })
        case .local(let avatarImage):
            // NOTE: setAvatarByIdentifier 是为了避免下载icon和本地icon之间的复用影响
            miniIconView.setAvatarByIdentifier("", avatarKey: "", completion: { [weak miniIconView] _ in
                miniIconView?.backgroundColor = UIColor.clear
            })
            miniIconView.image = avatarImage
        }
    }
}

public final class FeedCardAvatarUtil {
    public static func getBadgeInfo(feedPreview: FeedPreview) -> FeedCardBadgeInfo {
        let unreadCount = Int(feedPreview.basicMeta.unreadCount)
        // 没有未读，则返回nil
        guard unreadCount > 0 else {
            return FeedCardBadgeInfo(type: .none, style: .weak)
        }
        // 有未读
        if feedPreview.basicMeta.isRemind {
            // 如果是强提醒
            switch feedPreview.basicMeta.feedCardBaseCategory {
            case .inbox:
                return FeedCardBadgeInfo(type: .label(.number(unreadCount)), style: .strong)
            case .done:
                return FeedCardBadgeInfo(type: .label(.number(unreadCount)), style: .middle)
            case .unknown:
                return FeedCardBadgeInfo(type: .label(.number(unreadCount)), style: .strong)
            @unknown default:
                return FeedCardBadgeInfo(type: .label(.number(unreadCount)), style: .strong)
            }
        }

        // 以下都是弱提醒(免打扰)
        // 会话盒子分组，显示灰点提醒
        if feedPreview.basicMeta.feedCardBaseCategory == .done {
            return FeedCardBadgeInfo(type: .dot(.lark), style: .weak)
        }

        // 普通分组
        switch FeedBadgeBaseConfig.badgeStyle {
        case .weakRemind:
            // 灰色数字提醒
            return FeedCardBadgeInfo(type: .label(.number(unreadCount)), style: .weak)
        @unknown default:
            // 灰点提醒
            return FeedCardBadgeInfo(type: .dot(.lark), style: .strong)
        }
    }

    public static func setBorderImage(avatarView: LarkMedalAvatar, isBorderVisible: Bool) {
        if isBorderVisible {
            avatarView.updateBorderImage(Resources.LarkFeedBase.urgentBorderImage)
        } else {
            avatarView.updateBorderImage(nil)
        }
    }
}
