//
//  BlockMenuItem.swift
//  SKDoc
//
//  Created by zoujie on 2021/1/20.
//  

import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import SKFoundation

public enum BlockMenuType: String {
    case iconWithText // 同时有icon和text
    case iconAlone // 独立的纯icon
    case iconInGroup // 组内icon
    case iconWithDownArrow // 带向下箭头的icon
    case iconWithRightArrow // 带向右箭头的icon
    case group // 包含一组icon
    case separator // 分割线
}

public final class BlockMenuItem: Equatable, GroupableItem {
    public var id: String
    public var panelId: String
    public var text: String?
    public var enable: Bool?
    public var selected: Bool?
    public var members: [BlockMenuItem]? // 用于类似对齐、缩进样式的分组菜单项
    public var foregroundColor: [String: Any]?
    public var backgroundColor: [String: Any]?
    public var type: BlockMenuType?
    public var action: (() -> Void)?
    public var groupId: String = ""

    public init(id: String,
                panelId: String,
                text: String? = "",
                enable: Bool? = true,
                selected: Bool? = false,
                members: [BlockMenuItem]? = nil,
                foregroundColor: [String: Any]? = nil,
                backgroundColor: [String: Any]? = nil,
                type: BlockMenuType? = .iconWithText,
                groupId: String = "",
                action: (() -> Void)? = nil) {
        self.id = id
        self.panelId = panelId
        self.text = text
        self.enable = enable
        self.selected = selected
        self.members = members
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.action = action
        self.type = type
        self.groupId = groupId
    }

    /// load icon image by current button's identifier
    ///
    /// - Parameter identifier: button identifier
    /// - Returns: icon image
    // nolint: long_function
    public func loadImage(iconSize: CGSize? = nil) -> UIImage? {
        let type = BlockMenuV2Identifier(rawValue: id)
        let resType = BlockMenuIdentifier(rawValue: id)
        guard type != nil || resType != nil else { return nil }
        
        var iconImage: UIImage?
        var iconSize = iconSize
        switch type {
        case .bold:
            iconImage = UDIcon.boldOutlined
        case .italic:
            iconImage = UDIcon.italicOutlined
        case .underline:
            iconImage = UDIcon.underlineOutlined
        case .highlight:
            iconImage = UDIcon.textstyleOutlined
        case .plainText:
            iconImage = UDIcon.text2Outlined
        case .h1:
            iconImage = UDIcon.h1Outlined
        case .h2:
            iconImage = UDIcon.h2Outlined
        case .h3:
            iconImage = UDIcon.h3Outlined
        case .h4:
            iconImage = UDIcon.h4Outlined
        case .h5:
            iconImage = UDIcon.h5Outlined
        case .h6:
            iconImage = UDIcon.h6Outlined
        case .h7:
            iconImage = UDIcon.h7Outlined
        case .h8:
            iconImage = UDIcon.h8Outlined
        case .h9:
            iconImage = UDIcon.h9Outlined
        case .hn:
            iconImage = UDIcon.hnOutlined
        case .copy:
            iconImage = UDIcon.copyOutlined
        case .copyLink:
            iconImage = BundleResources.SKResource.Common.Global.icon_global_link_nor
        case .cut:
            iconImage = UDIcon.screenshotsOutlined
        case .comment:
            iconImage = UDIcon.addCommentOutlined
        case .delete:
            iconImage = UDIcon.deleteTrashOutlined
        case .style:
            iconImage = UDIcon.textAaOutlined
        case .align:
            iconImage = UDIcon.typographyOutlined
        case .checkbox:
            iconImage = UDIcon.todoOutlined
        case .alignleft:
            iconImage = UDIcon.leftAlignmentOutlined
        case .aligncenter:
            iconImage = UDIcon.centerAlignmentOutlined
        case .alignright:
            iconImage = UDIcon.rightAlignmentOutlined
        case .blockalignleft:
            iconImage = UDIcon.leftAlignmentOutlined
        case .blockaligncenter:
            iconImage = UDIcon.centerAlignmentOutlined
        case .blockalignright:
            iconImage = UDIcon.rightAlignmentOutlined
        case .indentleft:
            iconImage = UDIcon.reduceIndentationOutlined
        case .indentright:
            iconImage = UDIcon.increaseIndentationOutlined
        case .strikethrough:
            iconImage = UDIcon.horizontalLineOutlined
        case .codelist:
            iconImage = UDIcon.codeblockOutlined
        case .blockquote:
            iconImage = UDIcon.referenceOutlined
        case .inlinecode:
            iconImage = UDIcon.codeOutlined
        case .insertorderedlist:
            iconImage = UDIcon.orderListOutlined
        case .insertunorderedlist:
            iconImage = UDIcon.disorderListOutlined
        case .insertcodeblock:
            iconImage = UDIcon.codeblockOutlined
        case .editPencilKit:
            iconImage = BundleResources.SKResource.Common.Tool.icon_tool_edit_nor
        case .blockbackground:
            iconImage = UDIcon.styleSetOutlined
        case .focusTask:
            iconImage = UDIcon.subscribeAddOutlined
        case .checkDetails:
            iconImage = UDIcon.viewinchatOutlined
        case .checkList:
            iconImage = UDIcon.todoOutlined
        case .cancelRealtimeReference:
            iconImage = UDIcon.cancelLinkOutlined
        case .cancelSyncTask:
            iconImage = UDIcon.cancelSyncTaskOutlined
        case .more:
            iconImage = UDIcon.moreOutlined
        case .fileDownload:
            iconImage = UDIcon.downloadOutlined
        case .fileOpenWith:
            iconImage = UDIcon.windowNewOutlined
        case .fileSaveToDrive:
            iconImage = UDIcon.cloudUploadOutlined
        case .contentReaction:
            iconImage = UDIcon.thumbsupOutlined.ud.withTintColor(UDColor.orange)
        case .caption:
            iconImage = UDIcon.feedbackOutlined
        case .inlineAI:
            iconImage = UDIcon.myaiColorful
        case .forward:
            iconImage = UDIcon.shareOutlined
        case .addTime:
            iconImage = UDIcon.timeOutlined
        case .editTime:
            iconImage = UDIcon.timeOutlined
        case .startTime:
            iconImage = UDIcon.playRoundOutlined
        case .pauseTime:
            iconImage = UDIcon.pauseRoundOutlined
        case .syncedSource:
            iconImage = BundleResources.SKResource.Common.Tool.icon_link_record_outlined
            if iconSize == nil {
                iconSize = CGSize(width: 24, height: 24)
            }
        case .translate:
            iconImage = UDIcon.translateOutlined
        case .newLineBelow:
            iconImage = UDIcon.newJoinMeetingOutlined
        default:
            break
        }
        
        if iconImage == nil {
            switch resType {
            case .cut:
                iconImage = UDIcon.screenshotsOutlined
            case .comment:
                iconImage = UDIcon.addCommentOutlined
            case .copy:
                iconImage = UDIcon.copyOutlined
            case .copyLink:
                iconImage = BundleResources.SKResource.Common.Global.icon_global_link_nor
            case .delete:
                iconImage = UDIcon.deleteTrashOutlined
            case .debugCreator:
                iconImage = BundleResources.SKResource.Common.Icon.icon_setting_inter_outlined
            case .debugBlock:
                iconImage = BundleResources.SKResource.Common.Icon.icon_calendar_tittle_outlined
            case .refreshBlock:
                iconImage = BundleResources.SKResource.Common.Icon.icon_replace_outlined
            case .contentReaction:
                iconImage = UDIcon.thumbsupOutlined.ud.withTintColor(UDColor.orange)
            default:
                break
            }
        }
        
        let size = iconSize ?? CGSize(width: 20, height: 20)
        if let image = iconImage?.ud.resized(to: size) {
            return image
        } else {
           spaceAssertionFailure("must config block item icon")
        }
        return nil
    }

    public static func == (lhs: BlockMenuItem, rhs: BlockMenuItem) -> Bool {
        guard lhs.id == rhs.id else { return false }

        var mebersIsEqual: Bool = true
        if let lhsMembers = lhs.members,
           let rhsMembers = rhs.members,
           lhsMembers.count == rhsMembers.count {
            for (i, item) in lhsMembers.enumerated() {
                let enable = item.enable == rhsMembers[i].enable &&
                    item.selected == rhsMembers[i].selected &&
                    item.id == rhsMembers[i].id
                mebersIsEqual = mebersIsEqual && enable
            }
        } else {
            mebersIsEqual = false
        }
        
        let lhsBackgroundColor = lhs.backgroundColor?.filter {
            $0.key != "key"
        } as? [String: Float]

        let rhsBackgroundColor = rhs.backgroundColor?.filter {
            $0.key != "key"
        } as? [String: Float]

        let lhsForegroundColor = lhs.foregroundColor?.filter {
            $0.key != "key"
        } as? [String: Float]
        let rhsForegroundColor = rhs.foregroundColor?.filter {
            $0.key != "key"
        } as? [String: Float]

        return lhs.enable == rhs.enable &&
            lhs.selected == rhs.selected &&
            lhsBackgroundColor == rhsBackgroundColor &&
            lhsForegroundColor == rhsForegroundColor &&
            mebersIsEqual
    }
}
