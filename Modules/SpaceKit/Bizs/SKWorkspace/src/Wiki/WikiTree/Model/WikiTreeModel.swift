//
//  WikiTreeNode.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/23.
//

import Foundation
import UIKit
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import SpaceInterface
import LarkDocsIcon

// 树节点权限
public struct WikiTreeNodePermission: Codable, Equatable {
    public let canCreate: Bool
    public let canMove: Bool
    public let canDelete: Bool
    // 非级联删除是否可用，弱管控+无父节点编辑权限时为 false
    public let showDelete: Bool
    public let showSingleDelete: Bool
    public let canAddShortCut: Bool
    public let canStar: Bool
    public let canCopy: Bool
    public let isLocked: Bool
    public let canRename: Bool
    public let showMove: Bool
    public let canDownload: Bool?
    public let canExplorerStar: Bool?
    public let canExplorerPin: Bool?
    public let originCanCreate: Bool?    //用于shortcut下新建节点判断
    public let originCanAddShortcut: Bool? //用于判断本体是否可阅读
    public let originCanExplorerStar: Bool?
    public let originCanCopy: Bool? // 本体 canCopy
    public let originCanDownload: Bool?
    public let originCanExplorerPin: Bool?
    private let parentNodeMovePermission: WikiTreeNodeParentPermission?
    private let nodeMovePermission: WikiTreeNodeMovePermission?

    private enum CodingKeys: String, CodingKey {
        case canCreate = "can_create"
        case canMove = "can_move"
        case canDelete =  "can_delete"
        case showDelete = "show_delete"
        case showSingleDelete = "show_single_delete"
        case canAddShortCut = "can_add_shortcut"
        case canStar = "can_star"
        case canCopy = "can_clone"
        case isLocked = "is_locked"
        case canRename = "can_rename"
        case showMove = "show_move"
        case canDownload = "can_download"
        case canExplorerStar = "can_explorer_star"
        case canExplorerPin = "can_explorer_pin"
        case originCanCreate = "origin_can_create"
        case originCanAddShortcut = "origin_can_add_shortcut"
        case originCanExplorerStar = "origin_can_explorer_star"
        case originCanCopy = "origin_can_clone"
        case originCanDownload = "origin_can_download"
        case originCanExplorerPin = "origin_can_explorer_pin"
        case parentNodeMovePermission = "parent"
        case nodeMovePermission = "node"
    }
    
    public var parentIsRoot: Bool {
        parentNodeMovePermission?.isRoot ?? false
    }
    
    public var hasParentMovePermission: Bool {
        parentNodeMovePermission?.canMove ?? false
    }
    
    public var nodeCanMovePermission: Bool {
        nodeMovePermission?.canMove ?? false
    }

    public init(canCreate: Bool,
                canMove: Bool,
                canDelete: Bool,
                showDelete: Bool,
                showSingleDelete: Bool,
                canAddShortCut: Bool,
                canStar: Bool,
                canCopy: Bool,
                isLocked: Bool,
                canRename: Bool,
                showMove: Bool,
                canDownload: Bool?,
                canExplorerStar: Bool?,
                canExplorerPin: Bool?,
                originCanCreate: Bool?,
                originCanAddShortCut: Bool?,
                originCanExplorerStar: Bool?,
                originCanCopy: Bool?,
                originCanDownload: Bool?,
                originCanExplorerPin: Bool?,
                parentNodeMovePermission: WikiTreeNodeParentPermission?,
                nodeMovePermission: WikiTreeNodeMovePermission?) {
        self.canCreate = canCreate
        self.canMove = canMove
        self.canDelete = canDelete
        self.showDelete = showDelete
        self.showSingleDelete = showSingleDelete
        self.canAddShortCut = canAddShortCut
        self.canStar = canStar
        self.canCopy = canCopy
        self.isLocked = isLocked
        self.canRename = canRename
        self.showMove = showMove
        self.canDownload = canDownload
        self.canExplorerStar = canExplorerStar
        self.canExplorerPin = canExplorerPin
        self.originCanCreate = originCanCreate
        self.originCanAddShortcut = originCanAddShortCut
        self.originCanExplorerStar = originCanExplorerStar
        self.originCanCopy = originCanCopy
        self.originCanDownload = originCanDownload
        self.originCanExplorerPin = originCanExplorerPin
        self.parentNodeMovePermission = parentNodeMovePermission
        self.nodeMovePermission = nodeMovePermission
    }


    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<WikiTreeNodePermission.CodingKeys> = try decoder.container(keyedBy: WikiTreeNodePermission.CodingKeys.self)

        self.canCreate = try container.decode(Bool.self, forKey: .canCreate)
        self.canMove = try container.decode(Bool.self, forKey: .canMove)
        self.canDelete = try container.decode(Bool.self, forKey: .canDelete)
        self.showDelete = try container.decodeIfPresent(Bool.self, forKey: .showDelete) ?? false
        self.showSingleDelete = try container.decodeIfPresent(Bool.self, forKey: .showSingleDelete) ?? false
        self.canAddShortCut = try container.decode(Bool.self, forKey: .canAddShortCut)
        self.canStar = try container.decode(Bool.self, forKey: .canStar)
        self.canCopy = try container.decode(Bool.self, forKey: .canCopy)
        self.isLocked = try container.decode(Bool.self, forKey: .isLocked)
        self.canRename = try container.decode(Bool.self, forKey: .canRename)
        self.showMove = try container.decode(Bool.self, forKey: .showMove)
        self.canDownload = try container.decodeIfPresent(Bool.self, forKey: .canDownload)
        self.canExplorerStar = try container.decodeIfPresent(Bool.self, forKey: .canExplorerStar)
        self.canExplorerPin = try container.decodeIfPresent(Bool.self, forKey: .canExplorerPin)
        self.originCanCreate = try container.decodeIfPresent(Bool.self, forKey: .originCanCreate)
        self.originCanAddShortcut = try container.decodeIfPresent(Bool.self, forKey: .originCanAddShortcut)
        self.originCanExplorerStar = try container.decodeIfPresent(Bool.self, forKey: .originCanExplorerStar)
        self.originCanCopy = try container.decodeIfPresent(Bool.self, forKey: .originCanCopy)
        self.originCanDownload = try container.decodeIfPresent(Bool.self, forKey: .originCanDownload)
        self.originCanExplorerPin = try container.decodeIfPresent(Bool.self, forKey: .originCanExplorerPin)
        self.parentNodeMovePermission = try container.decodeIfPresent(WikiTreeNodeParentPermission.self, forKey: .parentNodeMovePermission)
        self.nodeMovePermission = try container.decodeIfPresent(WikiTreeNodeMovePermission.self, forKey: .nodeMovePermission)
    }

}

public struct WikiTreeNodeParentPermission: Codable, Equatable {
    public let isRoot: Bool  // 父节点是否是root节点
    public let canMove: Bool // 父节点是否有移动权限
    
    private enum CodingKeys: String, CodingKey {
        case isRoot = "root"
        case canMove = "can_move_from"
    }
    public init(isRoot: Bool, canMove: Bool) {
        self.isRoot = isRoot
        self.canMove = canMove
    }
}

public struct WikiTreeNodeMovePermission: Codable, Equatable {
    public let canMove: Bool
    
    enum CodingKeys: String, CodingKey {
        case canMove = "can_be_moved"
    }
    public init(canMove: Bool) {
        self.canMove = canMove
    }
}

// 空间节点权限
public struct WikiSpacePermission: Codable {
    public let canEditFirstLevel: Bool
    public let isWikiMember: Bool
    public let isWikiAdmin: Bool

    private enum CodingKeys: String, CodingKey {
        case canEditFirstLevel = "can_edit_first_level"  //是否能新建一级节点
        case isWikiMember = "is_wiki_member"            // 是否为空间成员，用于展示空间问答入口
        case isWikiAdmin = "can_manage_space"           // 是否为空间管理员，用于展示空间问答入口
    }

    public init(canEditFirstLevel: Bool, isWikiMember: Bool, isWikiAdmin: Bool) {
        self.canEditFirstLevel = canEditFirstLevel
        self.isWikiMember = isWikiMember
        self.isWikiAdmin = isWikiAdmin
    }
}

// 用户空间权限
public struct WikiUserSpacePermission: Codable, Equatable {

    public let canStarWiki: Bool
    public let canViewGeneralInfo: Bool

    private enum CodingKeys: String, CodingKey {
        case canStarWiki = "star_wiki" // 是否能置顶节点
        case canViewGeneralInfo = "view_wiki_general_info" // 知识库基本信息是否可见
    }

    public init(canViewGeneralInfo: Bool, canStarWiki: Bool) {
        self.canViewGeneralInfo = canViewGeneralInfo
        self.canStarWiki = canStarWiki
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // 后端没给或解析失败用 false 兜底
        canStarWiki = try container.decodeIfPresent(Bool.self, forKey: .canStarWiki) ?? false
        canViewGeneralInfo = try container.decodeIfPresent(Bool.self, forKey: .canViewGeneralInfo) ?? false
    }

    public static let `default` = WikiUserSpacePermission(canViewGeneralInfo: false, canStarWiki: false)
}

extension DocsType {
    public func wikiTreeHighlightIcon(with name: String) -> UIImage {
        switch self {
        case .file:
            let ext = SKFilePath.getFileExtension(from: name)
            let fileType = DriveFileType(fileExtension: ext)
            return fileType.wikiTreeHighlightIcon
        default:
            return UDIcon.getIconByKey(squareColorfulIconKey)
        }
    }

    public func wikiTreeNormalIcon(with name: String) -> UIImage {
        switch self {
        case .file:
            let ext = SKFilePath.getFileExtension(from: name)
            let fileType = DriveFileType(fileExtension: ext)
            return fileType.wikiTreeNormalIcon
        case .wikiCatalog:
            return UDIcon.folderOutlined
        default:
            return UDIcon.getIconByKey(outlinedIconKey)
        }
    }

    public func wikiTreeNormalShortcutIcon(with name: String) -> UIImage {
        switch self {
        case .file:
            let ext = SKFilePath.getFileExtension(from: name)
            let fileType = DriveFileType(fileExtension: ext)
            return fileType.wikiTreeNormalShortcutIcon
        case .wikiCatalog:
            spaceAssertionFailure("catalog should not be used with shortcut")
            return UDIcon.folderOutlined
        default:
            return UDIcon.getIconByKey(shortcutOutlinedIconKey)
        }
    }
}

extension DriveFileType {
    var wikiTreeHighlightIcon: UIImage {
        let iconKey = squareColorfulImageKey ?? .fileUnknowColorful
        return UDIcon.getIconByKey(iconKey)
    }

    var wikiTreeNormalIcon: UIImage {
        let iconKey = outlinedImageKey ?? .fileLinkOtherfileOutlined
        return UDIcon.getIconByKey(iconKey)
    }

    var wikiTreeNormalShortcutIcon: UIImage {
        let iconKey = shortcutOutlinedImageKey ?? .fileLinkOtherfileShortcutOutlined
        return UDIcon.getIconByKey(iconKey)
    }
}
