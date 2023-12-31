//
//  FeedActionItem.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2023/6/27.
//

import RustPB
import LarkModel

public enum FeedActionType: Hashable {
    case done           // 已完成
    case shortcut       // 置顶
    case flag           // 标记
    case mute           // 免打扰
    case label          // 加入标签
    case deleteLabel    // 移除标签
    case debug          // 调式
    case clearBadge     // 清未读
    case blockMsg       // 机器人不再接收消息
    case joinTeam       // 加入团队
    case jump           // 跳转
    case teamHide       // 团队隐藏
    case removeFeed     // 移除feed

    //【统一规则】Action 唯一排序规则, 不在数组中的元素会在 sort 过程中被移除
    static let sortRule: [FeedActionType] = [
        .shortcut,
        .flag,
        .joinTeam,
        .label,
        .clearBadge,
        .blockMsg,
        .mute,
        .done,
        .deleteLabel,
        .debug,
        .teamHide
    ]

    // 按 sortRule 数组顺序存储排序的字典 indexDict = [Action类型: 排序索引值]
    static let indexDict: [FeedActionType: Int] = {
        var dict: [FeedActionType: Int] = [:]
        for (index, element) in sortRule.enumerated() {
            dict[element] = index
        }
        return dict
    }()

    // 对数组做排序处理
    public static func sort(_ types: [FeedActionType]) -> [FeedActionType] {
        // 过滤掉不在 indexDict 中的元素
        let validArr = types.filter { Self.indexDict[$0] != nil }

        // 按照 indexDict 来排序
        let sortedArr = validArr.sorted {
            if let index1 = Self.indexDict[$0], let index2 = Self.indexDict[$1] {
                return index1 < index2
            }
            return false
        }

        return sortedArr
    }

    public static func clickTrackValue(type: FeedActionType, feedPreview: FeedPreview) -> String {
        switch type {
        case .done:
            return "finished"
        case .shortcut:
            return feedPreview.basicMeta.isShortcut ? "cancel_top" : "top"
        case .flag:
            return feedPreview.basicMeta.isFlaged ? "un_mark" : "mark"
        case .mute:
            return feedPreview.basicMeta.isRemind ? "mute" : "unmute"
        case .label:
            return "label"
        case .deleteLabel:
            return "remove_label"
        case .debug:
            return "debug"
        case .clearBadge:
            return "clearBadge"
        case .blockMsg:
            return feedPreview.preview.chatData.mutedBotP2P ? "forbidden" : "allow"
        case .joinTeam:
            return "add_to_team"
        case .jump, .teamHide, .removeFeed:
            return ""
        @unknown default:
            return ""
        }
    }
}

public struct FeedActionModel {
    public let feedPreview: FeedPreview
    public let channel: Basic_V1_Channel
    public let groupType: Feed_V1_FeedFilter.TypeEnum?
    public let bizType: FeedBizType?
    public let event: FeedActionEvent?
    public let labelId: Int64?
    public let chatItem: Basic_V1_Item?

    // feed 自身/基础数据
    public let basicData: IFeedPreviewBasicData?

    // 关联的业务数据
    public let bizData: FeedPreviewBizData?

    // 附带的自定义数据
    public let extraData: [AnyHashable: Any]?

    public weak var fromVC: UIViewController?
    public init(feedPreview: FeedPreview,
                channel: Basic_V1_Channel,
                event: FeedActionEvent? = nil,
                groupType: Feed_V1_FeedFilter.TypeEnum? = nil,
                bizType: FeedBizType? = nil,
                labelId: Int64? = nil,
                chatItem: Basic_V1_Item? = nil,
                fromVC: UIViewController? = nil,
                basicData: IFeedPreviewBasicData? = nil,
                bizData: FeedPreviewBizData? = nil,
                extraData: [AnyHashable: Any]? = nil) {
        self.feedPreview = feedPreview
        self.channel = channel
        self.event = event
        self.groupType = groupType
        self.bizType = bizType
        self.labelId = labelId
        self.chatItem = chatItem
        self.fromVC = fromVC
        self.basicData = basicData
        self.bizData = bizData
        self.extraData = extraData
    }
}

// 只聚焦FeedActionItem自身的UI元素和响应交互事件,不感知何场景调用
public protocol FeedActionBaseItem {
    var type: FeedActionType { get }
    var bizType: FeedPreviewType? { get }
    var viewModel: FeedActionViewModelInterface? { get }
    var handler: FeedActionHandlerInterface { get }
}

public struct FeedActionItem: FeedActionBaseItem {
    public let type: FeedActionType
    public let viewModel: FeedActionViewModelInterface?
    public let handler: FeedActionHandlerInterface
    public let bizType: FeedPreviewType?
    public init(type: FeedActionType,
                viewModel: FeedActionViewModelInterface?,
                handler: FeedActionHandlerInterface,
                bizType: FeedPreviewType? = nil) {
        self.type = type
        self.bizType = bizType
        self.viewModel = viewModel
        self.handler = handler
    }
}

public protocol FeedActionViewModelInterface {
    // Action 标题 (目前多事件共用统一文案)
    var title: String { get }
    // 长按唤起的菜单选项 Icon
    var contextMenuImage: UIImage { get }
    // 侧滑唤起的选项 Icon (可选)
    var swipeEditImage: UIImage? { get }
    // 侧滑唤起的选项底色 (可选)
    var swipeBgColor: UIColor? { get }
}

public extension FeedActionViewModelInterface {
    var swipeEditImage: UIImage? { return nil }
    var swipeBgColor: UIColor? { return nil }
}
